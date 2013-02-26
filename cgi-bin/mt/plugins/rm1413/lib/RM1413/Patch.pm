package RM1413::Patch;

use strict;
use warnings;

sub init {
    # Only for override.
    # Do nothing.
}

no warnings 'redefine';
require MT::Theme::StaticFiles;
*MT::Theme::StaticFiles::apply = sub {
    my ( $element, $theme, $blog ) = @_;
    return unless $blog->site_path;

    my $dirs = $element->{data} or return 1;
    my $exts = MT->config->ThemeStaticFileExtensions
        || MT::Theme::StaticFiles::_default_allowed_extensions();
    $exts = [ split /[\s,]+/, $exts ] if !ref $exts;
    for my $dir (@$dirs) {
        next if $dir =~ /[^\w\-\.]/;
        my $src = File::Spec->catdir( $theme->path, 'blog_static', $dir );
        my $dst = File::Spec->catdir( $blog->site_path, $dir );
        my $result
            = $theme->install_static_files( $src, $dst, allow => $exts, );
    }
    return 1;
};

require MT::Blog;
my $origin = \&MT::Blog::apply_theme;
*MT::Blog::apply_theme = sub {
    my $blog = shift;
    my $app = MT->instance;
    return 1 if 'MT::App::Upgrader' ne ref $app;
    return 1 unless $blog->site_path;
    $origin->( $blog, @_ );
};

sub cb_blog_template_set_change {
    my $cb = shift;
    my ($opt) = @_;
    my $app = MT->instance;
    return if 'MT::App::Upgrader' ne ref $app;

    my $website = $opt->{blog}
        or return;

    $website->apply_theme()
        or return;
}

sub disable_plugin {
    my $plugin = MT->component('rm1413');
    my $switch = MT->config('PluginSwitch') || {};
    $switch->{$plugin->{plugin_sig}} = 0;
    MT->config('PluginSwitch', $switch, 1);
    MT->config->save_config();
}

1;
