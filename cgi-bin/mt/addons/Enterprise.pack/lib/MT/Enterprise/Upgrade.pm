# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::Upgrade;

use strict;

sub fix_blob_for_mssqlserver {
    my $self = shift;
    my (%param) = @_;

    my $driver = MT->config->ObjectDriver;
    return unless $driver =~ /MSSQLServer/i;

    $self->progress(
        $self->translate_escape(
            'Fixing binary data for Microsoft SQL Server storage...')
    );

    require MT::Session;
    my $sess_iter = MT::Session->load_iter();
    while ( my $sess_obj = $sess_iter->() ) {
        $sess_obj->data( pack( 'H*', $sess_obj->data ) )
            if defined $sess_obj->data;
        $sess_obj->save;
    }

    require MT::PluginData;
    my $pd_iter = MT::PluginData->load_iter();
    while ( my $pd_obj = $pd_iter->() ) {
        $pd_obj->data( pack( 'H*', $pd_obj->data ) ) if defined $pd_obj->data;
        $pd_obj->save;
    }

    1;
}

1;
