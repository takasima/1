# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::DDL::UMSSQLServer;

use strict;
use warnings;
use base qw( MT::ObjectDriver::DDL::MSSQLServer );

sub type2db {
    my $ddl = shift;
    my ($def) = @_;
    return undef if !defined $def;
    my $type = $def->{type};
    if ( $type eq 'string' ) {
        return 'nvarchar(' . $def->{size} . ')' if ( $def->{size} < 8000 );
        return 'ntext';
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
        return 'ntext';
    }
    elsif ( $type eq 'float' ) {
        return 'float';
    }
    Carp::croak( "undefined type: " . $type );
}

1;
