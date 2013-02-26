package TinyMCE::Plugin;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( build_tmpl );

sub _set_editor_prefs {
    my ( $cb, $app, $param ) = @_;
    my $plugin = MT->component( 'TinyMCE' );
#    my $tmpl_dir = File::Spec->catdir( $plugin->path, 'alt-tmpl' );
#    $app->config( 'AltTemplatePath', $tmpl_dir );
#    my $static_path = $app->static_path;

    my $editor_style_css = $plugin->get_config_value( 'editor_style_css' );
    my $lang;
    if( my $blog = $app->blog ){
        my $scope = 'blog:'. $blog->id;
        $editor_style_css = $plugin->get_config_value( 'editor_style_css', $scope );
        $editor_style_css = $plugin->get_config_value( 'editor_style_css' ) unless $editor_style_css;
        my %args = ( blog => $blog );
        $editor_style_css = build_tmpl( $app, $editor_style_css, \%args );
    }
    $param->{ 'original_editor_style_css' } = $editor_style_css;
    $param->{ 'editor_plugins' } = $plugin->get_config_value( 'editor_plugins' );
    $param->{ 'original_theme_advanced_buttons1' } = $plugin->get_config_value( 'theme_advanced_buttons1' );
    $param->{ 'original_theme_advanced_buttons2' } = $plugin->get_config_value( 'theme_advanced_buttons2' );
    $param->{ 'original_theme_advanced_buttons3' } = $plugin->get_config_value( 'theme_advanced_buttons3' );
    $param->{ 'original_theme_advanced_buttons4' } = $plugin->get_config_value( 'theme_advanced_buttons4' );
    $param->{ 'original_theme_advanced_buttons5' } = $plugin->get_config_value( 'theme_advanced_buttons5' );
    $param->{ 'lang' } = $app->user ? $app->user->preferred_language : MT->config->DefaultLanguage;
    $param->{ 'plugin' } = 1;
    $param->{ 'editor_skin' } = $plugin->get_config_value( 'editor_skin' );
    $param->{ 'editor_advanced_setting' } = $plugin->get_config_value( 'editor_advanced_setting' );
    $param->{ 'header_toolbar' } = $plugin->get_config_value( 'editor_toolbar_position' );
}

sub _set_editor_settings {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'TinyMCE' );
    my $search = quotemeta( q{<mt:var name="html_head">} );
    my $plugin_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'TinyMCE.tmpl' );
    my $insert = qq{<mt:include name="$plugin_tmpl" component="TinyMCE">};
    $$tmpl =~ s/($search)/$insert$1/;
}

1;