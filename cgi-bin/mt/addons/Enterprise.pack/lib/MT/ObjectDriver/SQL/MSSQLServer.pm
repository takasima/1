# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::SQL::MSSQLServer;

use strict;
use warnings;
use base qw( MT::ObjectDriver::SQL );
use DBI qw(:sql_types);

*distinct_stmt = \&MT::ObjectDriver::SQL::_subselect_distinct;

my $VARCHAR = 'VARCHAR';

sub new {
    my $class = shift;
    my %param = @_;
    $VARCHAR = 'NVARCHAR' if MT->config->PublishCharset =~ m/UTF-?8/i;
    my $cd   = delete $param{count_distinct};
    my $stmt = $class->SUPER::new(%param);
    if ($cd) {
        $stmt->{count_distinct} = $cd;
    }
    if ( my $cols = $stmt->binary ) {
        foreach my $col ( keys %$cols ) {
            $stmt->transform->{$col} = "($col COLLATE Japanese_Bin2)";
        }
    }
    $stmt->column_mutator(
        sub {
            my ($col) = @_;
            if ( exists $stmt->lob_columns->{$col} ) {
                my $converted = "CONVERT($VARCHAR(MAX), $col)";
                for my $arg (qw( range range_incl not null not_null like )) {
                    if (   exists( $stmt->{$arg} )
                        && exists( $stmt->{$arg}->{$col} ) )
                    {
                        $stmt->{$arg}->{$converted}
                            = delete $stmt->{$arg}->{$col};
                    }
                }
                return $converted;
            }
            $col;
        }
    );
    return $stmt;
}

#--------------------------------------#
# Instance Methods

sub as_sql {
    my $stmt = shift;
    my $sql  = '';
    if ( my $cols = $stmt->date_columns ) {
        foreach my $col ( keys %$cols ) {
            next unless $stmt->select_map->{$col};
            my $val = delete $stmt->select_map->{$col};
            delete $stmt->select_map_reverse->{$val};
            map { $_ = "CONVERT($VARCHAR, $_, 20) AS $_" if $_ eq $col }
                @{ $stmt->select };
            my $conv = "CONVERT($VARCHAR, $col, 20) AS $col";
            $stmt->select_map->{$conv}        = $val;
            $stmt->select_map_reverse->{$val} = $conv;
        }
    }
    my $lob_cols = $stmt->lob_columns;
    if ( !(%$lob_cols) && defined( $stmt->from_stmt ) ) {
        $lob_cols = $stmt->from_stmt->lob_columns;
    }

    my $can_distinct = 1;
    if (%$lob_cols) {
        if ( my $sel_cols = $stmt->select ) {
            foreach my $k ( keys %$lob_cols ) {
                $can_distinct = 0, last if grep { $_ eq $k } @$sel_cols;
            }
        }
    }

    ## Distinct query that selects LOB columns isn't possible in MSSQLServer.
    ## MT::OD::DBD::MSSQLServer overrides load and load_iter for it.
    $stmt->distinct(0) unless $can_distinct;

    if ( my $inner_stmt = $stmt->from_stmt ) {
        if ( my $cd = delete $inner_stmt->{count_distinct} ) {
            my ($col) = each %$cd;
            $inner_stmt->add_select( $col => $col )
                unless exists $inner_stmt->select_map->{$col};
        }
        my $first_column = shift @{ $inner_stmt->select };
        ## Ugly hack - SQL Server requires TOP clause in subquery which has ORDER BY clause.
        my $with_top  = "TOP 9999999999 $first_column";
        my $map_value = delete $inner_stmt->select_map->{$first_column};
        unshift @{ $inner_stmt->select }, $with_top;
        $inner_stmt->select_map->{$with_top}          = $map_value;
        $inner_stmt->select_map_reverse->{$map_value} = $with_top;
        my $limit = $inner_stmt->limit;
        if ( defined $limit ) {
            $stmt->limit($limit);
            $inner_stmt->limit(0);
        }
        my $offset = $inner_stmt->offset;
        if ( defined $offset ) {
            $stmt->offset($offset);
            $inner_stmt->offset(0);
        }
    }
    my $limit  = $stmt->limit;
    my $offset = $stmt->offset;
    if ($offset) {
        my $main_stmt = __PACKAGE__->new;
        my $group_by = ( $stmt->group && @{ $stmt->group } ) ? 1 : 0;

        my $sort_clause;

        foreach my $orig_col ( @{ $stmt->select } ) {
            if ($group_by) {

                # group_by call - aggregated column must be
                # in the select list of inner statment
                # while outer statement should not have
                # aggregate function.
                if ( $orig_col =~ /^([\w_\-\.]+)\((.+)\)\s+AS\s+(.+)$/ ) {
                    my ( $func, $col, $as_col ) = ( lc($1), $2, $3 );
                    if (   ( 'convert' ne $func )
                        && ( 'row_number' ne $func )
                        && ( 'over' ne $func ) )
                    {
                        $main_stmt->add_select($as_col);
                        foreach ( @{ $stmt->order } ) {
                            if ( $as_col eq $_->{column} ) {
                                $sort_clause = $stmt->as_aggregate('order')
                                    unless $sort_clause;
                                $_->{column} = "$func($col)";
                            }
                        }
                        next;
                    }
                }
            }
            $main_stmt->add_select( $orig_col => $orig_col );
        }
        foreach my $orig_bind ( @{ $stmt->bind } ) {
            push @{ $main_stmt->bind }, $orig_bind;
        }

        my $over_clause = $stmt->as_aggregate('order');
        unless ($sort_clause) {
            $sort_clause = $over_clause;
            my $order = $stmt->order;
            if ( $order && ( 'ARRAY' ne ref($order) ) ) {
                $order = [$order];
            }
            foreach (@$order) {
                my $col = $_->{column};
                next if exists( $stmt->select_map->{$col} );
                $col =~ s{ \A [^_]+_ }{}xms;    # appropriate for all?
                next if exists( $stmt->select_map_reverse->{$col} );
                $stmt->add_select( $_->{column} );
                $main_stmt->add_select( $_->{column} );
            }
        }

        $stmt->add_select( "ROW_NUMBER() OVER($over_clause) as line" =>
                "ROW_NUMBER() OVER($over_clause) as line" );
        $stmt->order(undef);
        $main_stmt->from_stmt($stmt);
        if ($limit) {
            my $where
                = 'BETWEEN '
                . ( 1 + $offset ) . ' AND '
                . ( $offset + $limit );
            $main_stmt->add_where( 'line', \$where );
            $stmt->limit(0);
        }
        else {
            $main_stmt->add_where( 'line', \"> $offset" );
        }
        $main_stmt->add_select('line');
        $stmt->offset(0);
        $sql = $main_stmt->SUPER::as_sql(@_);
        $sql = $main_stmt->_do_as_sqls( $sql, $sort_clause );
        return $sql;
    }
    elsif ($limit) {
        $stmt->limit(0);

        $stmt->as_aggregate('order');
        my $order = $stmt->order;
        if ( $order && ( 'ARRAY' ne ref($order) ) ) {
            $order = [$order];
        }
        if ($order) {
            foreach (@$order) {
                my $col = $_->{column};
                next if exists( $stmt->select_map->{$col} );
                $col =~ s{ \A [^_]+_ }{}xms;    # appropriate for all?
                next if exists( $stmt->select_map_reverse->{$col} );
                $stmt->add_select( $_->{column} );
            }
        }

        $sql = $stmt->SUPER::as_sql(@_);

        # Ugly hack to workaround a bug? in DBD::ODBC that
        # it can't recognize unicode characters bound to
        # a parameter passed in where clause when there
        # are more than one statement in sequence.
        $sql =~ s/^SELECT( (?:DISTINCT )?)/SELECT$1TOP($limit) /i;
        return $sql;
    }
    elsif ( $stmt->distinct ) {
        if ( $stmt->as_aggregate('order') ) {
            my $order = $stmt->order;
            if ( $order && ( 'ARRAY' ne ref($order) ) ) {
                $order = [$order];
            }
            if ($order) {
                foreach (@$order) {
                    my $col = $_->{column};
                    next if exists( $stmt->select_map->{$col} );
                    $col =~ s{ \A [^_]+_ }{}xms;    # appropriate for all?
                    next if exists( $stmt->select_map_reverse->{$col} );
                    $stmt->add_select( $_->{column} );
                }
            }
        }
    }
    $sql .= $stmt->SUPER::as_sql(1);
    $sql;
}

sub field_decorator {
    my $stmt = shift;
    my ($class) = @_;
    return sub {
        my ($term)       = @_;
        my $field_prefix = $class->datasource;
        my $new_term     = q();
        while (
            $term =~ /extract\((\w+)\s+from\s+([\w_]+)\)(\s*desc|asc)?/ig )
        {
            $new_term .= ', ' if $new_term;
            $new_term .= "$1($2)";
            $new_term .= $3   if defined $3;
        }
        $new_term = $term unless $new_term;
        for my $col ( @{ $class->column_names } ) {
            $new_term =~ s/\b$col\b/${field_prefix}_$col/g;
        }
        return $new_term;
    };
}

sub _do_as_sqls {
    my $stmt = shift;
    my ( $sql, $sort_clause ) = @_;
    $sql .= $stmt->as_sql_where;
    $sql .= $stmt->as_aggregate('group');
    $sql .= $stmt->as_sql_having;
    $sql .= " $sort_clause";
    $sql .= $stmt->as_limit;
}

sub _mk_term {
    my $stmt = shift;
    my ( $col, $val ) = @_;

    # Try really hard to get the correct column name
    my ( $table_name, $column_name ) = $col =~ m{ \A mt_(\w+)\.(\w+) }xms;
    if ($table_name) {
        $column_name = $table_name . '_' . $column_name;
    }
    else {
        $column_name = $col;
    }
    if ( 'HASH' eq ref($val) ) {
        if ( !exists $val->{op} ) {

            # hash-style value, containing hints on operation
            if ( exists $val->{like} ) {
                $val->{like} =~ s/([^\[]?)([\^\[\]\_])([^\]]?)/$1\[$2\]$3/g;
            }
            if ( exists $val->{not_like} ) {
                $val->{not_like}
                    =~ s/([^\[]?)([\^\[\]\_])([^\]]?)/$1\[$2\]$3/g;
            }
        }
    }
    if ( $stmt->like->{$column_name} ) {
        if ( ref($val) eq 'HASH' ) {
            $val->{value} =~ s/([^\[]?)([\^\[\]\_])([^\]]?)/$1\[$2\]$3/g;
        }
        elsif ( !ref($val) ) {
            $val =~ s/([^\[]?)([\^\[\]\_])([^\]]?)/$1\[$2\]$3/g;
        }
    }

    return $stmt->SUPER::_mk_term( $col, $val );
}

sub as_aggregate {
    my $stmt = shift;
    my ($set) = @_;

    my $m = sub {
        my ($col) = @_;
        exists $stmt->lob_columns->{$col}
            ? "CONVERT($VARCHAR(MAX), $col)"
            : $col;
    };

    if ( my $attribute = $stmt->$set() ) {
        my $elements
            = ( ref($attribute) eq 'ARRAY' ) ? $attribute : [$attribute];
        foreach (@$elements) {
            $_->{column} = $m->( $_->{column} );

            # Remove column alias
            if ( $_->{column} =~ /^([\w_\-\.]+\(.+\))+\s+AS\s+.+$/i ) {
                $_->{column} = $1;
            }
        }
        return
            uc($set) . ' BY '
            . join( ', ',
            map { $_->{column} . ( $_->{desc} ? ( ' ' . $_->{desc} ) : '' ) }
                @$elements )
            . "\n";
    }

    return '';
}

1;
