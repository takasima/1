# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::DDL::Oracle;

use strict;
use warnings;
use base qw( MT::ObjectDriver::DDL );

sub can_add_column   {1}
sub can_drop_column  {1}
sub can_alter_column {0}

sub index_defs {
    my $ddl          = shift;
    my ($class)      = @_;
    my $driver       = $class->driver;
    my $dbh          = $driver->r_handle;
    my $field_prefix = $class->datasource;
    my $table_name   = $class->table_name;
    my $sth          = $dbh->prepare(<<SQL)
SELECT ui.index_name, ui.index_type, ui.uniqueness, uic.column_name, uic.column_position
FROM user_indexes ui INNER JOIN user_ind_columns uic 
ON ui.index_name = uic.index_name AND ui.table_name = uic.table_name
WHERE ui.table_name = UPPER('$table_name')
SQL
        or print STDERR $dbh->errstr;
    $sth->execute or print STDERR $dbh->errstr;

    my $bags   = {};
    my $unique = {};
    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = lc $row->{'INDEX_NAME'};
        next unless $key =~ m/^(mt_)?\Q$field_prefix\E_/;
        $key = 'mt_' . $key unless $key =~ m/^mt_/;

        my $type = $row->{'INDEX_TYPE'};

        # ignore fulltext or other unrecognized indexes for now
        next unless $type eq 'NORMAL';

        my $seq       = $row->{'COLUMN_POSITION'};
        my $col       = lc $row->{'COLUMN_NAME'};
        my $is_unique = $row->{'UNIQUENESS'};
        $key =~ s/^mt_\Q$field_prefix\E_//;
        $col =~ s/^\Q$field_prefix\E_//;
        $unique->{$key} = 1 unless $is_unique eq 'NONUNIQUE';
        my $idx_bag = $bags->{$key} ||= [];
        $idx_bag->[ $seq - 1 ] = $col;
    }
    $sth->finish;
    if ( !%$bags ) {
        return undef;
    }

    my $defs = {};
    foreach my $key ( keys %$bags ) {
        my $cols = $bags->{$key};
        if ( $unique->{$key} ) {
            $defs->{$key} = { columns => $cols, unique => 1 };
        }
        else {
            if ( ( @$cols == 1 ) && ( $key eq $cols->[0] ) ) {
                $defs->{$key} = 1;
            }
            else {
                $defs->{$key} = { columns => $cols };
            }
        }
    }

    return $defs;
}

sub column_defs {
    my $ddl = shift;
    my ($class) = @_;

    my $driver        = $class->driver;
    my $table_name    = $class->table_name;
    my $uc_table_name = uc($table_name);
    my $field_prefix  = $class->datasource;
    my $dbh           = $driver->r_handle;
    return undef unless $dbh;

    my $sth = $dbh->column_info(
        '%',            uc( MT->config->DBUser ),
        $uc_table_name, uc( $field_prefix . '_%' )
    ) or return undef;
    $sth->execute or return undef;

    my $defs = {};
    while ( my $row = $sth->fetchrow_hashref ) {
        my $colname = lc $row->{COLUMN_NAME};
        next if $colname !~ m/^\Q$field_prefix\E_/i;
        $colname =~ s/^\Q$field_prefix\E_//i;
        my $coltype  = $row->{TYPE_NAME};
        my $size     = $row->{COLUMN_SIZE} || '0';
        my $nullable = $row->{NULLABLE};
        $coltype = $ddl->db2type( $coltype, $size );
        $defs->{$colname}{type} = $coltype;

        if ( ( $coltype eq 'string' ) && $size ) {

# DBD Oracle fails to return CHAR_LENGTH and returns DATA_LENGTH from ALL_TAB_COLUMNS
# Fix by Arvind per http://opensource.atlassian.com/projects/hibernate/browse/HBX-1027
            $size = $size / 2;

            $defs->{$colname}{size} = $size;
        }
        if ( !$nullable || ( $coltype eq 'timestamp' ) ) {
            $defs->{$colname}{not_null} = 1;
        }
        else {
            $defs->{$colname}{not_null} = 0;
        }
    }
    $sth->finish;
    if ( !%$defs ) {
        return undef;
    }
    my $pk_sql = <<SQL;
SELECT column_name
FROM user_cons_columns uc
INNER JOIN user_constraints u on uc.constraint_name = u.constraint_name
WHERE constraint_type = 'P'
AND u.table_name = '$uc_table_name'
SQL
    local $dbh->{RaiseError} = 0;
    $sth = $dbh->prepare($pk_sql)
        or return $defs;
    $sth->execute
        or return $defs;
    while ( my $row = $sth->fetchrow_hashref ) {
        my $colname = lc $row->{COLUMN_NAME};
        next if $colname !~ m/^\Q$field_prefix\E_/i;
        $colname =~ s/^\Q$field_prefix\E_//i;
        if ( exists $defs->{$colname} ) {
            $defs->{$colname}{key} = 1;
        }
    }
    $sth->finish;
    return $defs;
}

sub drop_sequence {
    my $ddl = shift;
    my ($class) = @_;

    my $driver = $class->driver;
    my $dbh    = $driver->rw_handle;

    # do this, but ignore error since it usually means the
    # sequence didn't exist to begin with
    if ( my $col = $class->properties->{primary_key} ) {
        if ( ref $col ) {
            $col = $col->[1];
        }
        my $def = $class->column_def($col);
        if (   exists( $def->{auto} )
            && $def->{auto}
            && (   'integer' eq $def->{type}
                || 'number' eq substr( $ddl->type2db($def), 0, 6 ) )
            )
        {
            my $seq = $driver->dbd->sequence_name($class);
            local $dbh->{RaiseError} = 0;
            $dbh->do("DROP SEQUENCE $seq");
        }
    }
    1;
}

sub create_sequence {
    my $ddl = shift;
    my ($class) = @_;

    my $driver = $class->driver;
    my $dbh    = $driver->rw_handle;

    if ( my $col = $class->properties->{primary_key} ) {
        ## If it's a complex primary key, use the second half.
        if ( ref $col ) {
            $col = $col->[1];
        }
        my $def = $class->column_def($col);
        if (   exists( $def->{auto} )
            && $def->{auto}
            && (   'integer' eq $def->{type}
                || 'number' eq substr( $ddl->type2db($def), 0, 6 ) )
            )
        {
            my $table_name   = $class->table_name;
            my $field_prefix = $class->datasource;
            my $max_sql
                = 'SELECT MAX('
                . $field_prefix . '_'
                . $col
                . ') FROM '
                . $table_name;
            my ($start) = $dbh->selectrow_array($max_sql);
            my $seq = $driver->dbd->sequence_name($class);
            $dbh->do( "CREATE SEQUENCE $seq"
                    . ( $start ? ( ' START WITH ' . ( $start + 1 ) ) : '' ) );
        }
    }
    return 1;
}

sub db2type {
    my $ddl = shift;
    my ( $type, $size ) = @_;
    $size ||= 0;
    $type = lc $type;
    $type =~ s/\(.+//;
    if ( $type eq 'number' ) {
        return 'bigint' if $size == 20;

        # DBD Oracle fails to return correct Type based on NUMBER length
        # Fix by Arvind
        return 'smallint' if $size == 5;
        return 'boolean'  if $size == 1;

        return 'integer';
    }
    elsif ( $type eq 'varchar' ) {
        return 'string';
    }
    elsif ( $type eq 'varchar2' ) {
        return 'string';
    }
    elsif ( $type eq 'nvarchar' ) {
        return 'string';
    }
    elsif ( $type eq 'nvarchar2' ) {
        return 'string';
    }
    elsif ( $type eq 'clob' ) {
        return 'text';
    }
    elsif ( $type eq 'blob' ) {
        return 'blob';
    }
    elsif ( $type eq 'timestamp' ) {
        return 'timestamp';
    }
    elsif ( $type eq 'date' ) {
        return 'datetime';
    }
    elsif ( $type eq 'text' ) {
        return 'text';
    }
    elsif ( $type eq 'float' ) {
        return 'float';
    }
    Carp::croak( "undefined type: " . $type );
}

sub type2db {
    my $ddl   = shift;
    my ($def) = @_;
    my $type  = $def->{type};
    if ( $type eq 'string' ) {
        my $size = $def->{size};

        #$size = 2000 if $size == 255;
        return 'nvarchar2(' . $size . ')';
    }
    elsif ( $type eq 'bigint' ) {
        return 'number(20)';
    }
    elsif ( $type eq 'smallint' ) {
        return 'number(5)';
    }
    elsif ( $type eq 'boolean' ) {
        return 'number(1)';
    }
    elsif ( $type eq 'datetime' ) {
        return 'date';
    }
    elsif ( $type eq 'timestamp' ) {
        return 'timestamp';
    }
    elsif ( $type eq 'integer' ) {
        return 'integer';
    }
    elsif ( $type eq 'blob' ) {
        return 'blob';
    }
    elsif ( $type eq 'text' ) {
        return 'clob';
    }
    elsif ( $type eq 'float' ) {
        return 'float';
    }
}

sub alter_column_sql {
    my $ddl = shift;
    my $sql = $ddl->SUPER::alter_column_sql(@_);
    $sql =~ s/\bMODIFY\b/ALTER COLUMN/;
    return $sql;
}

sub drop_column_sql {
    my $ddl = shift;
    my ( $class, $name ) = @_;
    my $driver       = $class->driver;
    my $table_name   = $class->table_name;
    my $field_prefix = $class->datasource;
    return "ALTER TABLE $table_name DROP COLUMN ${field_prefix}_$name";
}

sub column_sql {
    my $ddl = shift;
    my ( $class, $name ) = @_;

    my $driver       = $class->driver;
    my $dbd          = $driver->dbd;
    my $field_prefix = $class->datasource;
    my $def          = $class->column_def($name);
    my $type         = $ddl->type2db($def);
    my $nullable     = '';
    if ( $def->{not_null} ) {
        $nullable = ' NOT NULL';
    }
    my $default = '';
    if ( exists $def->{default} ) {
        my $value = $def->{default};
        if ( ( $def->{type} =~ m/time/ ) || $dbd->is_date_col($name) ) {
            $value = $driver->r_handle->quote( $dbd->ts2db($value) );
        }
        elsif ( $def->{type} !~ m/int|float|boolean/ ) {
            $value = $driver->r_handle->quote($value);
        }
        $default = ' DEFAULT ' . $value;
    }
    my $key = '';
    if ( $def->{key} ) {
        $key = ' PRIMARY KEY';
    }
    return
          $field_prefix . '_' 
        . $name . ' ' 
        . $type 
        . $default
        . $nullable
        . $key;
}

sub cast_column_sql {
    my $ddl = shift;
    my ( $class, $name, $from_def ) = @_;
    my $field_prefix = $class->datasource;
    my $def          = $class->column_def($name);
    if ( $def->{type} eq 'blob' ) {
        return "CAST(${field_prefix}_$name AS " . $ddl->type2db($def) . ")";
    }
    return "${field_prefix}_$name";
}

sub drop_index_sql {
    my $ddl = shift;
    my ( $class, $key ) = @_;
    my $table_name = $class->table_name;

    my $props   = $class->properties;
    my $indexes = $props->{indexes};
    return q() unless exists( $indexes->{$key} );

    if ( ref $indexes->{$key} eq 'HASH' ) {
        my $idx_info = $indexes->{$key};
        if ( $idx_info->{unique} && $ddl->can_add_constraint ) {
            return
                "ALTER TABLE $table_name DROP CONSTRAINT ${table_name}_$key";
        }
    }

    return "DROP INDEX ${table_name}_$key";
}

1;
