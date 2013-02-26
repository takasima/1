# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::Author;

use strict;

sub pre_save_author {
    my ( $eh, $obj, $orig_obj ) = @_;
    if (   ( 'MT' ne MT->config->AuthenticationModule )
        && ( !MT->config->ExternalUserManagement )
        && (   ( $obj->name ne $orig_obj->name )
            || ( $obj->name && !$obj->external_id ) )
        )
    {
        $obj->external_id( lc $obj->name );
    }
    1;
}

sub delete_author_ext_auth_filter {
    my ( $cb, $app, $obj, $return_arg ) = @_;
    return 1 unless $app->config->ExternalUserManagement;
    return 1 unless $app->config->AuthenticationModule eq 'LDAP';
    require MT::LDAP;
    my $ldap = MT::LDAP->new
        or return $app->errtrans( "Loading MT::LDAP failed: [_1].",
        MT::LDAP->errstr );
    my $dn = $ldap->get_dn( $obj->name );
    $return_arg->{author_ldap_found} = 1 if $dn;
    return 1;
}

1;
