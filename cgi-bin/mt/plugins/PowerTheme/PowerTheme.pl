package MT::Plugin::PowerTheme;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

our $VERSION = '0.5';
our $SCHEMA_VERSION = '0.1';

my $plugin = __PACKAGE__->new( {
    id => 'PowerTheme',
    key => 'powertheme',
    name => 'PowerTheme',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => '<__trans phrase="Powerful theme for you.">',
    version => $VERSION,
    schema_version => $SCHEMA_VERSION,
    l10n_class => 'PowerTheme::L10N',
} );
MT->add_plugin( $plugin );
sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        object_types => {
            template => {
                subject => 'text revisioned',
            }
        },
        callbacks => {
#            'post_apply_theme' => '$powertheme::PowerTheme::Plugin::_cb_post_apply_theme',
            'MT::App::Comments::pre_run' => '$powertheme::PowerTheme::Plugin::_cb_comments_pre_run',
            'MT::App::CMS::template_param.edit_template' => '$powertheme::PowerTheme::Plugin::_edit_template_param',
            'post_apply_theme' => [
                { handler => '$powertheme::PowerTheme::Plugin::_cb_post_apply_theme_website' },
                { handler => '$powertheme::PowerTheme::Plugin::_cb_post_apply_theme_blog' },
                { handler => '$powertheme::PowerTheme::Plugin::_cb_post_apply_theme_remove_unedition_templates' },
            ],
#            'MT::App::CMS::template_source.edit_blog' => '$powertheme::PowerTheme::Plugin::_check_theme',
#            'MT::App::CMS::template_source.list_theme' => '$powertheme::PowerTheme::Plugin::_check_theme',
        }
    } );
}

1;
