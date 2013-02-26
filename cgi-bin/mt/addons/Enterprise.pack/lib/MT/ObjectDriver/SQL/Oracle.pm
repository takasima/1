# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::SQL::Oracle;

use strict;
use warnings;
use base qw( MT::ObjectDriver::SQL );

sub new {
    my $class = shift;
    my %param = @_;
    my $stmt  = $class->SUPER::new(%param);
    my $cols  = $stmt->lob_columns;

    # Although LIKE search now uses INSTR (see _mk_term) and
    # DISTINCT query is completely done in MT::OD::DBD::Oracle,
    # SUBSTR is still required sometimes for exact comparison
    # because there is no method defined in DBMS_LOB object
    # that calculates equality of a CLOB and a string.
    foreach my $col ( keys %$cols ) {
        my $t = $stmt->transform->{$col};
        my $conv;
        if ( $t && ( $t !~ /DBMS_LOB.SUBSTR/ ) ) {
            $conv = "DBMS_LOB.SUBSTR($t, 4000)";
        }
        elsif ($t) {
            $conv = $t;
        }
        else {
            $conv = "DBMS_LOB.SUBSTR($col, 4000)";
        }
        $stmt->transform->{$col} = $conv;
    }
    $stmt;
}

*distinct_stmt = \&MT::ObjectDriver::SQL::_subselect_distinct;

#--------------------------------------#
# Instance Methods

sub as_sql {
    my $stmt = shift;
    my $sql  = '';

    my $sel_items = scalar @{ $stmt->select };

    # if $sel_items == 0, this is likely an 'exists' test
    my $work_stmt;
    if ( $sel_items && ( $stmt->limit || $stmt->offset ) ) {
        my $group_by = ( $stmt->group && @{ $stmt->group } ) ? 1 : 0;

        # reconstruct statement to be oracle-friendly
        my $middle_stmt = __PACKAGE__->new;
        my $main_stmt   = __PACKAGE__->new;
        for my $dbcol ( @{ $stmt->select } ) {
            my $col = $dbcol;
            $col =~ s{ \A [^_]+_ }{}xms;    # appropriate for all?

            if ($group_by) {

                # group_by call - aggregated column must be
                # in the select list of inner statment
                # while outer statement should not have
                # aggregate function.
                if ( $dbcol =~ /^([\w_\-\.]+)\(.+\)\s+AS\s+(.+)$/ ) {
                    my ( $func, $as_col ) = ( $1, $2 );
                    if ( 'dbms_lob.substr' ne $func ) {
                        $main_stmt->add_select($as_col);
                        $middle_stmt->add_select($as_col);
                        next;
                    }
                }
            }
            $main_stmt->add_select( $dbcol => $col );
            $middle_stmt->add_select( $dbcol => $col );
        }

        $middle_stmt->add_select( 'ROWNUM as line' => 'ROWNUM as line' );
        $middle_stmt->from_stmt($stmt);

        $main_stmt->from_stmt($middle_stmt);

        my $limit  = $stmt->limit;
        my $offset = $stmt->offset;

        if ( $limit && $offset ) {
            my $where
                = 'BETWEEN '
                . ( 1 + $offset ) . ' AND '
                . ( $offset + $limit );
            $main_stmt->add_where( 'line', \$where );
            $stmt->limit(0);
            $stmt->offset(0);
        }
        elsif ($offset) {
            $main_stmt->add_where( 'line', \"> $offset" );
            $stmt->offset(0);
        }
        else {
            $main_stmt->add_where( 'line', \"<= $limit" );
            $stmt->limit(0);
        }
        $work_stmt = $main_stmt;
    }
    else {
        $work_stmt = $stmt;
    }

    my $old_sel;
    if ( @{ $work_stmt->select } ) {
        $old_sel = $work_stmt->select;

        $sql = 'SELECT ';
        my $lob_cols = $work_stmt->lob_columns;
        if ( !(%$lob_cols) && defined( $work_stmt->from_stmt ) ) {
            $lob_cols = $work_stmt->from_stmt->lob_columns;
        }

        my $can_distinct = 1;
        if (%$lob_cols) {
            if ( my $sel_cols = $work_stmt->select ) {
                foreach my $k ( keys %$lob_cols ) {
                    $can_distinct = 0, last if grep { $_ eq $k } @$sel_cols;
                }
            }
        }

        ## Distinct query that selects LOB columns isn't possible in MSSQLServer.
        ## MT::OD::DBD::MSSQLServer overrides load and load_iter for it.
        $stmt->distinct(0) unless $can_distinct;

        if ( $work_stmt->distinct ) {
            $sql .= 'DISTINCT ';

            if ( $work_stmt->as_aggregate('order') ) {
                my $order = $work_stmt->order;
                if ( $order && ( 'ARRAY' ne ref($order) ) ) {
                    $order = [$order];
                }
                foreach (@$order) {
                    my $col = $_->{column};
                    next if exists( $work_stmt->select_map->{$col} );
                    $col =~ s{ \A [^_]+_ }{}xms;    # appropriate for all?
                    next if exists( $work_stmt->select_map_reverse->{$col} );
                    $work_stmt->add_select( $_->{column} );
                }
            }
        }

        ## Ugly... We need push ROW_NUMBER() because Oracle returns ORA-00932 when
        ## the LOB columns exists in SQL including the summary-functions. Oracle 10g works fine...
        ## e.g.
        ## select count(*) mt_table_column from mt_table
        ## where DBMS_LOB.SUBSTR(LOB_COLUMN) group by (mt_table_column)
        my $group_by = ( $stmt->group && @{ $stmt->group } ) ? 1 : 0;
        if ( %$lob_cols && $group_by ) {
            require MT::Object;
            my $driver = MT::Object->driver;
            my $dbh    = $driver->r_handle;
            require DBD::Oracle::GetInfo;
            my $ora_ver = DBD::Oracle::GetInfo::sql_dbms_version($dbh);
            push @{ $work_stmt->select }, "ROW_NUMBER() OVER (ORDER BY 1) R"
                if $ora_ver =~ m/^11\..*/;
        }

        $sql .= join( ', ', @{ $work_stmt->select } ) . "\n";

        $work_stmt->select( [] );
    }
    if ( $work_stmt->from_stmt ) {
        $sql .= 'FROM ';
        my @from_tbls = @{ $work_stmt->from };
        if ( 0 < scalar(@from_tbls) ) {
            $sql .= join ', ', @{ $work_stmt->from };
            $sql .= ', ';
        }
        $sql
            .= '('
            . $work_stmt->from_stmt->as_sql(@_)
            . ") t\n";    # t is the subquery alias
        $sql .= $work_stmt->as_sql_where;
        $sql .= $work_stmt->as_aggregate('group');
        $sql .= $work_stmt->as_sql_having;
        $sql .= $work_stmt->as_aggregate('order');

        #    $sql .= $work_stmt->as_limit;
    }
    else {
        $sql .= $work_stmt->SUPER::as_sql(@_);

        ## Check if we generated an unbounded query for mt_session, since we're seeing those in production.
        ## TODO: remove this. Or generalize it into query auditing.
        my @from_tbls = @{ $work_stmt->from };
        if ( 1 == scalar @from_tbls && $from_tbls[0] eq 'mt_session' ) {
            if (   !$work_stmt->where
                || !@{ $work_stmt->where }
                || $sql !~ m{ where }xmsi )
            {
                MT->log->debug(
                    Carp::longmess(
                        "Generated unbounded query on mt_session [$sql]")
                );
            }
        }
    }

    $work_stmt->select($old_sel) if $old_sel;
    return $sql;
}

sub _mk_term {
    my $stmt = shift;
    my ( $col, $val ) = @_;

    # In the event that an 'IN' list of values exceeds 1000 items,
    # break it into multiple clauses, OR'd together.
    if ( ( ref($val) eq 'ARRAY' ) && ( !ref( $val->[0] ) ) ) {

        # term is going to generate an 'IN' list of scalars
        # check size of array to see if it falls within acceptable
        # size for Oracle (1000 terms maximum per 'IN' clause)
        if ( @$val > 1000 ) {

            # we need to break this up into multiple IN clauses
            my @full_set = @$val;
            my $new_val  = [];
            while ( my @subset = splice( @full_set, 0, 1000 ) ) {
                push @$new_val, '-or' unless @$new_val;
                push @$new_val, { $col => \@subset };
            }
            return $stmt->_parse_array_terms($new_val);
        }
    }

    my $lob_columns = $stmt->lob_columns;
    return $stmt->SUPER::_mk_term( $col, $val )
        unless $lob_columns && %$lob_columns;

    # Try really hard to get the correct column name
    my ( $table_name, $column_name ) = $col =~ m{ \A mt_(\w+)\.(\w+) }xms;
    if ($table_name) {
        $column_name = $table_name . '_' . $column_name;
    }
    else {
        $column_name = $col;
    }

    if (   !exists( $lob_columns->{$column_name} )
        && $stmt->select_map_reverse
        && %{ $stmt->select_map_reverse }
        && ( exists( $stmt->select_map_reverse->{$column_name} ) ) )
    {
        $column_name = $stmt->select_map_reverse->{$column_name};
    }
    unless ( exists $lob_columns->{$column_name} ) {
        if ( my $m = $stmt->column_mutator ) {
            $column_name = $m->($col);
        }
        return $stmt->SUPER::_mk_term( $col, $val )
            unless exists( $lob_columns->{$column_name} );
    }

    # Disabling transform when doing like search
    local $stmt->{transform}->{$column_name} = $column_name
        if ( ( 'HASH' eq ref($val) && !exists $val->{op} )
        && ( exists $val->{like} || exists $val->{not_like} ) )
        || $stmt->like->{$column_name};

    if (   ( 'SCALAR' eq ref($val) )
        && ( ' IS NULL' eq uc($$val) ) )
    {
        local $stmt->{transform}->{$column_name}
            = "DBMS_LOB.GETLENGTH($column_name)";
        return $stmt->SUPER::_mk_term( $col, $val );
    }

    return $stmt->SUPER::_mk_term( $col, $val );
}

sub _push_bound_value {
    my ( $bind, $value ) = @_;
    my $prev_val = pop @$bind;
    push @$bind, $value, $prev_val;
}

sub as_aggregate {
    my $stmt = shift;
    my ($set) = @_;

    if ( my $attribute = $stmt->$set() ) {
        my $elements
            = ( ref($attribute) eq 'ARRAY' ) ? $attribute : [$attribute];
        foreach (@$elements) {
            $_->{column} = $stmt->transform->{ $_->{column} }
                if $stmt->transform->{ $_->{column} };

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
