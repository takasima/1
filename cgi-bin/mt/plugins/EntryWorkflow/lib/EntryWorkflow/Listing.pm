package EntryWorkflow::Listing;
use strict;

use MT::Util qw( encode_html );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can );
use EntryWorkflow::Util;

sub _list_actions {
    my ( $meth, $component ) = @_;
    my $app = MT->instance;
    my $actions = {
        add_category_perm => {
            label       => 'Add permission for category',
            mode        => 'add_perms_for_category',
            return_args => 1,
            args        => { dialog => 1 },
            order       => 600,
            dialog => 1,
            condition => sub {
                if ( my $blog = $app->blog ) {
                    if ( $blog->is_blog ) {
                        my $user = $app->user;
                        if ( $user->is_superuser ) {
                            return  1;
                        }
                        if ( $user->permissions( $blog->id )->can_administer_blog ) {
                            return 1;
                        }
                    }
                }
                return 0;
            },
        },
        remove_category_perm => {
            label       => 'Remove permission for category',
            mode        => 'remove_perms_for_category',
            return_args => 1,
            args        => { dialog => 1 },
            order       => 700,
            dialog => 1,
            condition => sub {
                if ( my $blog = $app->blog ) {
                    if ( $blog->is_blog ) {
                        my $user = $app->user;
                        if ( $user->is_superuser ) {
                            return  1;
                        }
                        if ( $user->permissions( $blog->id )->can_administer_blog ) {
                            return 1;
                        }
                    }
                }
                return 0;
            },
        },
    }
}

sub _html_perms_for_category {
    my ( $prop, $obj ) = @_;
    my $app = MT->instance;
    return '-' unless $app->blog;
    my $perm = MT->model( 'permission' )->load( { author_id => $obj->id, blog_id => $app->blog->id } );
    return '-' unless $perm;
    my $plugin = MT->component( 'EntryWorkflow' );
    my $blog = $app->blog;
    my $show_link;
    if ( is_user_can( $blog, $obj, 'create_post' ) ) {
        if (! is_user_can( $blog, $obj, 'administer_blog' ) ) {
            $show_link = 1;
        }
    }
    my $text = '-';
    if ( my $category_ids = $perm->categories ) {
        my @ids = split( /,/, $category_ids );
        my @cats = MT->model( 'category' )->load( { id => \@ids, blog_id => $blog->id } );
        my @labels;
        if ( @cats ) {
            for my $c ( @cats ) {
                push ( @labels, MT::Util::encode_html( $c->label ) );
            }
        }
        $text = join( ',', @labels );
    }
    if ( $show_link ) {
        if ( $text eq '-' ) {
            $text = '<img src="' . MT->static_path . 'images/status_icons/create.gif" width="9" height="9" alt="' . $plugin->translate( 'Add permission for category' ) . '" title="' . $plugin->translate( 'Add permission for category' ) . '" />';
        }
        my $edit_link = $app->uri(
            mode => 'manage_perms_for_category',
            args => {
                author_id => $obj->id,
                blog_id => $blog->id,
                dialog => 1,
                magic_token => $app->current_magic,
            },
        );
        return qq{
            <a href="#" onclick="jQuery.fn.mtDialog.open('$edit_link');return false" class="mt-open-dialog">$text</a>
        }
    }
    return $text;
}

1;