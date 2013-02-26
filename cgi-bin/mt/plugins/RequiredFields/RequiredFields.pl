package MT::Plugin::RequiredFields;

use strict;
use warnings;

use MT;
use MT::Plugin;
use base qw( MT::Plugin );

our $VERSION = '0.0.8';

my $plugin = __PACKAGE__->new( {
    id => 'RequiredFields',
    key => 'requiredfields',
    name => 'RequiredFields',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => '<__trans phrase="Check required input fields.">',
    version => $VERSION,
    settings => new MT::PluginSettings( [
        [ 'standard_fields', { Default => '', Scope => 'blog' } ],
        [ 'ext_fields', { Default => '', Scope => 'blog' } ],
        [ 'category_equired', { Default => 0, Scope => 'blog' } ],
        [ 'preview_check', { Default => 0, Scope => 'blog' } ],
    ] ),
    blog_config_template => 'requiredfields_config.tmpl',
    l10n_class => 'RequiredFields::L10N',
} );
MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;

    $plugin->registry( {
        callbacks => {
            'template_source.edit_entry'
                => '$requiredfields::RequiredFields::Plugin::_append_scripts',
            'template_param.edit_entry'
                => '$requiredfields::RequiredFields::Plugin::_append_params',
        }
    } );
}

1;
