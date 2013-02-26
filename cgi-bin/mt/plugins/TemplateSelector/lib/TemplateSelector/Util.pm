package TemplateSelector::Util;
use strict;

use lib 'addons/PowerCMS.pack/lib';
use PowerCMS::Util qw( is_user_can static_or_support is_cms current_user current_blog );

sub get_default_template {
    my ( $blog_id, $class ) = @_;
    my $template = MT->model( 'template' )->load( { blog_id => $blog_id,
                                                    is_selector => 1,
                                                    is_default_selector => 1,
                                                    object_class => $class,
                                                  }
                                                );
    return $template;
}

sub get_templates_for_selector {
    my ( $blog_id, $class ) = @_;
    my @templates = MT->model( 'template' )->load( { blog_id => $blog_id,
                                                     is_selector => 1,
                                                     object_class => $class,
                                                   }
                                                 );
    return @templates;
}

sub remove_thumbnail {
    my ( $template ) = @_;
    if ( my $thumbnail_path = $template->thumbnail_path ) {
        my $plugin = MT->component( 'TemplateSelector' );
        my $thumbnail_file_path = File::Spec->catdir( static_or_support(), 'plugins', $plugin->id, 'thumbnail', $template->blog_id, $thumbnail_path );
        my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
        if ( $fmgr->exists( $thumbnail_file_path ) ) {
            return $fmgr->delete( $thumbnail_file_path );
        }
    }
}

sub can_create_template_selector {
    my ( $blog, $author, $class ) = @_;
    my $app = MT->instance;
    if ( is_cms( $app ) ) {
        if ( ! $author ) {
            $author = current_user( $app );
            unless ( $author ) {
                return 0;
            }
        }
        if ( ! $blog ) {
            $blog = current_blog( $app );
            unless ( $blog ) {
                return 0;
            }
        }
        if ( ! $class ) {
            $class = $app->param( '_type' );
            unless ( $class ) {
                return 0;
            }
        }
        if ( ! $class =~ /^(?:entry|page)$/ ) {
            return 0;
        }
        my $can_create_entry = $class eq 'entry' ? is_user_can( $blog, $author, 'create_post' ) : is_user_can( $blog, $author, 'manage_pages' );
        return ( is_user_can( $blog, $author, 'edit_templates' ) && $can_create_entry );
    }
    return 0;
}

sub can_template_selector {
    my ( $blog, $author ) = @_;
    my $app = MT->instance;
    if ( is_cms( $app ) ) {
        if ( ! $author ) {
            $author = current_user( $app );
        }
        if ( ! $blog ) {
            $blog = current_blog( $app );
        }
        if ( ! $blog ) {
            return 0;
        }
        return is_user_can( $blog, $author, 'edit_templates' );
    }
    return 0;
}

sub words_count {
    my ( $str ) = @_;
    my @words = split /\s?/, $str;
    return scalar @words;
}

1;