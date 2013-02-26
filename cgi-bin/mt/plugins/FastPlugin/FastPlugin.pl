package MT::Plugin::FastPlugin;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );
# use Time::HiRes;

my $plugin = __PACKAGE__->new( {
    id   => 'FastPlugin',
    key  => 'fastplugin',
    name => 'Fast Plugin',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => '<__trans phrase="Fast Loading PluginData.">',
    version => '0.3',
} );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        callbacks => {
            'MT::App::CMS::pre_run' => { handler => \&_pre_run, priority => 1, },
            'cms_save_permission_filter.plugindata' => sub {
                MT->instance->error( MT->translate( 'Invalid request.' ) );
            },
            'cms_delete_permission_filter.plugindata' => sub {
                MT->instance->error( MT->translate( 'Invalid request.' ) );
            },
        },
    } );
}

MT->add_plugin( $plugin );

sub _pre_run {
    return 1 if MT->config( 'ObjectDriver' ) ne 'DBI::mysql';
    my $app = MT->instance;
    # my $start = Time::HiRes::time();
    return if ( MT->request( 'plugin-fastplugin-init' ) );
    MT->request( 'plugin-fastplugin-init', 1 );
    my $plugin_settings;
    require MT::Memcached;
    # require FastPlugin::PluginSetting;
    my $memcached;
    if ( MT::Memcached->is_available ) {
        $memcached = MT::Memcached->instance;
        if ( ( $app->mode eq 'save_plugin_config' ) || ( $app->mode eq 'reset_plugin_config' ) ) {
            $memcached->set( 'plugin-fastplugin-plugin-settings' => undef );
            return;
        }
        $plugin_settings = $memcached->get( 'plugin-fastplugin-plugin-settings' );
        # $plugin_settings = undef; # for Debug.
        # $memcached->set( 'plugin-fastplugin-plugin-settings' => undef );
        # use Data::Dumper;
        # warn Dumper $plugin_settings;
    }
    if (! $plugin_settings ) {
        $plugin_settings = {};
        my @plugin_data;
        if (! $memcached ) {
            my ( $blog_id, $parent_id );
            if ( my $blog = $app->blog ) {
                $blog_id = $blog->id;
                if ( $blog->is_blog ) {
                    $parent_id = $blog->parent_id;
                }
            }
            my %terms1 = ( key => 'configuration' );
            my %terms2 = ( key => 'configuration:blog:' . $blog_id ) if $blog_id;
            my %terms3 = ( key => 'configuration:blog:' . $parent_id ) if $parent_id;
            require FastPlugin::PluginSetting;
            if (! $blog_id ) {
                @plugin_data = FastPlugin::PluginSetting->load( \%terms1 );
            } elsif (! $parent_id ) {
                @plugin_data = FastPlugin::PluginSetting->load( [ \%terms1, '-or', \%terms2 ] );
            } else {
                @plugin_data = FastPlugin::PluginSetting->load( [ \%terms1, '-or', \%terms2, '-or', \%terms3 ] );
            }
        } else {
            require MT::PluginData;
            @plugin_data = MT::PluginData->load();
            # warn Dumper @plugin_data;
        }
        for my $pdata_obj ( @plugin_data ) {
            my $key = $pdata_obj->key;
            my $plugin_name = $pdata_obj->plugin;
            my $plugin = MT->component( $plugin_name );
            my $data = $pdata_obj->data() || {};
            if ( $plugin ) {
                if ( $plugin->envelope && $plugin->envelope =~ /^addons/ ) {
                    next;
                }
                $plugin->apply_default_settings( $data, $pdata_obj->key );
            }
            if ( $key =~ m/:/ ) {
                $key =~ s/configuration:(.*)/$1/;
            } else {
                $key = 'system';
            }
            $pdata_obj->data( $data );
            $plugin_settings->{ $plugin_name }->{ $key } = $pdata_obj;
        }
        if ( $memcached && $plugin_settings ) {
            $memcached->set( 'plugin-fastplugin-plugin-settings' => $plugin_settings );
        }
    }
    for my $setting ( keys %$plugin_settings ) {
        MT->request( 'plugin_config.' . $setting, $plugin_settings->{ $setting } );
    }
    # my $now = Time::HiRes::time();
    # warn ( $now - $start );
}

1;
