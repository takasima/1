# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::DDL::MSSQLServer;

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
SELECT i.name AS index_name, i.type AS index_type, is_unique, is_primary_key, is_unique_constraint
, c.name AS column_name
, ic.key_ordinal AS key_ordinal
FROM sys.indexes AS i 
INNER JOIN sys.index_columns AS ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id 
INNER JOIN sys.columns AS c ON ic.column_id = c.column_id AND ic.object_id = c.object_id 
WHERE is_hypothetical = 0 
AND i.index_id <> 0 
AND i.object_id = OBJECT_ID('$table_name')
SQL
        or return undef;
    $sth->execute or return undef;

    my $bags   = {};
    my $unique = {};
    while ( my $row = $sth->fetchrow_hashref ) {
        my $key = $row->{'index_name'};
        next unless $key =~ m/^(mt_)?\Q$field_prefix\E_/;
        $key = 'mt_' . $key unless $key =~ m/^mt_/;

        my $type = $row->{'index_type'};

   # ignore HEAP and XML indexes for now ( 1 == CLUSTERED, 2 == NONCLUSTERED )
        next unless ( $type == 1 ) || ( $type == 2 );

        my $seq       = $row->{'key_ordinal'};
        my $col       = $row->{'column_name'};
        my $is_unique = $row->{'is_unique'} || $row->{'is_unique_constraint'};
        $key =~ s/^mt_\Q$field_prefix\E_//;
        $col =~ s/^\Q$field_prefix\E_//;
        $unique->{$key} = 1 if $is_unique;
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

    my $driver       = $class->driver;
    my $table_name   = $class->table_name;
    my $field_prefix = $class->datasource;
    my $dbh          = $driver->r_handle;
    return undef unless $dbh;

    local $dbh->{RaiseError} = 0;

    my $sql = <<SQL;
SELECT c.name column_name, t.name type_name, c.status, c.isnullable, c.length, i.is_primary_key
FROM syscolumns c 
INNER JOIN systypes t on c.xusertype=t.xusertype and c.usertype=t.usertype 
LEFT OUTER JOIN sys.index_columns ic on c.colid = ic.column_id AND c.id = ic.object_id
LEFT OUTER JOIN sys.indexes i on i.index_id = ic.index_id AND c.id = i.object_id
WHERE c.id = OBJECT_ID('$table_name')
SQL
    my $sth = $dbh->prepare($sql) or return undef;
    $sth->execute or return undef;
    my $defs = {};
    while ( my $row = $sth->fetchrow_hashref ) {
        my $colname = lc $row->{column_name};
        next if $colname !~ m/^\Q$field_prefix\E_/i;
        $colname =~ s/^\Q$field_prefix\E_//i;
        my $coltype = $row->{type_name};
        my $size    = $row->{'length'};
        $coltype = $ddl->db2type($coltype);
        $defs->{$colname}{type} = $coltype;
        $defs->{$colname}{auto} = ( $row->{status} == 0x80 ) ? 1 : 0;

        if ( ( $coltype eq 'string' ) && $size ) {
            $defs->{$colname}{size} = $size;
        }
        $defs->{$colname}{not_null} = ( $row->{isnullable} )     ? 0 : 1;
        $defs->{$colname}{key}      = ( $row->{is_primary_key} ) ? 1 : 0;
    }
    $sth->finish;
    if ( !%$defs ) {
        return undef;
    }
    $defs;
}

sub db2type {
    my $ddl = shift;
    my ($type) = @_;
    $type = lc $type;
    $type =~ s/\(.+//;
    if ( $type eq 'int' ) {
        return 'integer';
    }
    elsif ( $type eq 'smallint' ) {
        return 'smallint';
    }
    elsif ( $type eq 'bigint' ) {
        return 'bigint';
    }
    elsif ( $type eq 'tinyint' ) {
        return 'integer';
    }
    elsif ( $type eq 'varchar' ) {
        return 'string';
    }
    elsif ( $type eq 'nvarchar' ) {
        return 'string';
    }
    elsif ( $type eq 'char' ) {
        return 'string';
    }
    elsif ( $type eq 'text' ) {
        return 'text';
    }
    elsif ( $type eq 'ntext' ) {
        return 'text';
    }
    elsif ( $type eq 'image' ) {
        return 'blob';
    }
    elsif ( $type eq 'smalldatetime' ) {
        return 'datetime';
    }
    elsif ( $type eq 'datetime' ) {
        return 'datetime';
    }
    elsif ( $type eq 'float' ) {
        return 'float';
    }
    elsif ( $type eq 'real' ) {
        return 'float';
    }
    Carp::croak( "undefined type: " . $type );
}

sub type2db {
    my $ddl = shift;
    my ($def) = @_;
    return undef if !defined $def;
    my $type = $def->{type};
    if ( $type eq 'string' ) {
        return 'varchar(' . $def->{size} . ')' if ( $def->{size} < 8000 );
        return 'text';
    }
    elsif ( $type eq 'bigint' ) {
        return 'bigint';
    }
    elsif ( $type eq 'smallint' ) {
        return 'smallint';
    }
    elsif ( $type eq 'boolean' ) {
        return 'tinyint';
    }
    elsif ( $type eq 'timestamp' ) {
        return 'datetime';
    }
    elsif ( $type eq 'datetime' ) {
        return 'datetime';
    }
    elsif ( $type eq 'integer' ) {
        return 'int';
    }
    elsif ( $type eq 'blob' ) {
        return 'image';
    }
    elsif ( $type eq 'text' ) {
        return 'text';
    }
    elsif ( $type eq 'float' ) {
        return 'float';
    }
    Carp::croak( "undefined type: " . $type );
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
    my $sql
        = $field_prefix . '_' 
        . $name . ' ' 
        . $type
        . $nullable
        . $default
        . $key;
    $sql .= ' IDENTITY' if $def->{auto};
    return $sql;
}

sub cast_column_sql {
    my $ddl = shift;
    my ( $class, $name, $from_def ) = @_;
    my $field_prefix = $class->datasource;

    my $def = $class->column_def($name);
    if ( $def->{type} eq 'text' ) {
        return "CAST(${field_prefix}_$name AS " . $ddl->type2db($def) . ")";
    }
    return "${field_prefix}_$name";
}

sub add_column_sql {
    my $ddl = shift;
    my ( $class, $name ) = @_;
    my $sql = $ddl->column_sql( $class, $name );
    my $table_name = $class->table_name;
    return "ALTER TABLE $table_name ADD $sql";
}

sub alter_column_sql {
    my $ddl = shift;
    my ( $class, $name ) = @_;
    my $sql = $ddl->column_sql( $class, $name );
    my $table_name = $class->table_name;
    return "ALTER TABLE $table_name ALTER COLUMN $sql";
}

sub drop_column_sql {
    my $ddl = shift;
    my ( $class, $name ) = @_;
    my $driver       = $class->driver;
    my $table_name   = $class->table_name;
    my $field_prefix = $class->datasource;
    return "ALTER TABLE $table_name DROP COLUMN ${field_prefix}_$name";
}

sub insert_from_sql {
    my $ddl = shift;
    my ( $class, $db_defs ) = @_;
    my $table_name = $class->table_name;

    my $orig_sql = $ddl->SUPER::insert_from_sql(@_);
    my $sql
        = "BEGIN TRY SET IDENTITY_INSERT $table_name ON END TRY BEGIN CATCH END CATCH ";
    $sql .= $orig_sql;
    $sql
        .= "; BEGIN TRY SET IDENTITY_INSERT $table_name OFF END TRY BEGIN CATCH END CATCH;";
    return $sql;
}

sub create_table_as_sql {
    my $ddl        = shift;
    my ($class)    = @_;
    my $table_name = $class->table_name;
    return " SELECT * INTO ${table_name}_upgrade FROM $table_name";
}

1;
