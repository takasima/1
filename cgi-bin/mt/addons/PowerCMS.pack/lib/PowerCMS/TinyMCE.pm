package PowerCMS::TinyMCE;

use strict;
use warnings;

use PowerCMS::Util qw( get_powercms_config build_tmpl );

sub asset_insert_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;

    return 1 unless $app->param('edit_field') =~ /customfield_(.*)/;
    my $basename = $1;

    my $block = $tmpl->getElementById('insert_script');
    return 1 unless $block;

    my $blog  = $app->blog;
    my $field = $app->model('field')->load(
        {   basename => $basename,
            blog_id  => [ ( $blog ? ( $blog->id ) : () ), 0 ],
        },
        { 'sort' => 'blog_id', }
    );

    if ( $field && $field->type eq 'editor_textarea' ) {
        $block->innerHTML(
            qq{window.parent.app.insertHTML( '<mt:var name="upload_html" escape="js">', '<mt:var name="edit_field" escape="js">' );}
        );
    }
}

sub insert_editor_script {
    my ( $cb, $app, $param, $tmpl ) = @_;

    $app->setup_editor_param($param);
    my $header_include
        = ( $tmpl->getElementsByName('include/header.tmpl') || [] )->[0];
    my $editor_script
        = ( $tmpl->getElementsByName('editor_script_include') || [] )->[0];
    if ( !$editor_script && $header_include ) {
        $editor_script = $tmpl->createElement(
            'include',
            {   name => 'include/editor_script.tmpl',
                id   => 'editor_script_include',
            }
        );
        $tmpl->insertBefore( $editor_script, $header_include );
    }
}

sub _hdlr_import_tiny_mce_config {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;

    for my $i ( 1 .. 5 ) {
        $ctx->var( "original_theme_advanced_buttons$i",
            get_powercms_config( 'powercms', "theme_advanced_buttons$i" ) );

        $ctx->var( "original_source_buttons$i",
            get_powercms_config( 'powercms', "source_buttons$i" ) );
    }

    for my $k (qw(editor_plugins editor_advanced_setting)) {
        $ctx->var( $k, get_powercms_config( 'powercms', $k ) );
    }

    my $editor_style_css;
    if ( my $blog = $app->blog ) {
        $editor_style_css
            = get_powercms_config( 'powercms', 'editor_style_css', $blog );
        $editor_style_css
            = build_tmpl( $app, $editor_style_css, { blog => $blog } );
    }
    else {
        $editor_style_css
            = get_powercms_config( 'powercms', 'editor_style_css' );
    }

    $ctx->var( 'original_editor_style_css', $editor_style_css );
}

1;
