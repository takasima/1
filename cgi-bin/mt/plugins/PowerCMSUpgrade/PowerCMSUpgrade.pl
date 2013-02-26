package MT::Plugin::PowerCMSUpgrade;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );
our $SCHEMA_VERSION = '3.059';

my $plugin = __PACKAGE__->new( {
    id   => 'PowerCMSUpgrade',
    key  => 'powercmsupgrade',
    name => 'PowerCMS Upgrade Assistant',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => '<__trans phrase="This version of the plugin is to install/upgrade PowerCMS.  No other features are included.  You can safely remove this plugin after installing/upgrading PowerCMS.">',
    version => '2.0',
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
        config_settings => {
            TinyMCEMigrateBlogsPerStep => {
                default => 10,
            },
        },
        upgrade_functions => {
            tiny_mce_plugin_config_to_powercms_config => {
                version_limit => 3.059,
                handler       => sub {
                    eval q{
                        use PowerCMS::Util qw(set_powercms_config_values);
                    };

                    my ( $upgrade, %param ) = @_;

                    if ( !$param{'blog_ids'} ) {
                        migrate_tiny_mce_config_global(@_);
                    }
                    else {
                        migrate_tiny_mce_config_blog(@_);
                    }
                },
            },
        },
    } );
}

sub tiny_mce_plugin {
    MT->component('TinyMCE');
}

sub migrate_tiny_mce_config_global {
    my ( $upgrade, %param ) = @_;

    $upgrade->progress(
        $plugin->translate(
            'Migrate TinyMCE\'s plugin config to PowerCMS config...'
        )
    );

    my $tiny_mce_config = tiny_mce_plugin()->get_config_hash;

    set_powercms_config_values(
        'powercms',
        {   map { $_ => $tiny_mce_config->{$_} }
                qw(
                editor_style_css
                editor_plugins
                theme_advanced_buttons1
                theme_advanced_buttons2
                theme_advanced_buttons3
                theme_advanced_buttons4
                theme_advanced_buttons5
                editor_advanced_setting
                )
        }
    );
    tiny_mce_plugin()->reset_config;

    migrate_tiny_mce_config_add_steps_for_blog($upgrade);
}

sub migrate_tiny_mce_config_add_steps_for_blog {
    my ($upgrade) = @_;

    my @blog_ids = map { $_->key =~ /:(\d+)/ } MT->model('plugindata')->load(
        {   plugin => tiny_mce_plugin()->key || tiny_mce_plugin()->{name},
            key => { like => 'configuration:%' },
        },
        { fetchonly => ['key'], }
    );

    my $per_step = MT->config->TinyMCEMigrateBlogsPerStep;
    while (@blog_ids) {
        my @partition = splice( @blog_ids, 0, $per_step );
        $upgrade->add_step( 'tiny_mce_plugin_config_to_powercms_config',
            blog_ids => \@partition );
    }
}

sub migrate_tiny_mce_config_blog {
    my ( $upgrade, %param ) = @_;

    for my $blog_id ( @{ $param{blog_ids} } ) {
        my $scope           = "blog:$blog_id";
        my $tiny_mce_config = tiny_mce_plugin()->get_config_hash($scope);

        set_powercms_config_values(
            'powercms',
            {   map { $_ => $tiny_mce_config->{$_} }
                    qw(
                    editor_style_css
                    )
            },
            $blog_id
        );
        tiny_mce_plugin()->reset_config($scope);
    }
}

MT->add_plugin( $plugin );

1;
