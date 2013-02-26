package MT::Plugin::PowerCMSUpgrade;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );
our $SCHEMA_VERSION = '3.058';

my $plugin = __PACKAGE__->new( {
    id   => 'PowerCMSUpgrade',
    key  => 'powercmsupgrade',
    name => 'PowerCMS Upgrade Assistant',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => '<__trans phrase="This version of the plugin is to install/upgrade PowerCMS.  No other features are included.  You can safely remove this plugin after installing/upgrading PowerCMS.">',
    version => '1.03',
    schema_version => $SCHEMA_VERSION,
} );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        object_types => {
#            config => { powercms_config => 'blob' },
            blog   => { powercms_config => 'blob',
                        exclude_search => 'boolean' },
            entry  => { ext_datas => 'text', # OLD
                        unpublished_on => 'datetime',
                        unpublished => 'boolean' }, # OLD
            # entry  => { ext_data => 'text' },
            author => { bookmarks => 'hash meta' },
            powercmsconfig => 'PowerCMS::PowerCMSConfig',
            objectfolder => 'PowerCMS::ObjectFolder',
        },
    } );
}

MT->add_plugin( $plugin );

1;
