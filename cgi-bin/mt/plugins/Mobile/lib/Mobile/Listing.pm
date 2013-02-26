package Mobile::Listing;
use strict;

use MT::Util qw( encode_html );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can );

sub _list_actions_members {
    my ( $meth, $component ) = @_;
    my $app = MT->instance;
    my $actions = {
        add_category_at_mailpost => {
            label => 'Add category at mailpost',
            mode => 'add_category_at_mailpost',
            return_args => 1,
            args => { dialog => 1 },
            order => 800,
            dialog => 1,
            condition => sub {
                if ( my $blog = $app->blog ) {
                    if ( $blog->is_blog ) {
                        my $user = $app->user;
                        if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
                            return 1;
                        }
                    }
                }
                return 0;
            },
        },
        remove_category_at_mailpost => {
            label => 'Remove category at mailpost',
            mode => 'remove_category_at_mailpost',
            return_args => 1,
            args => { dialog => 1 },
            order => 900,
            dialog => 1,
            condition => sub {
                if ( my $blog = $app->blog ) {
                    if ( $blog->is_blog ) {
                        my $user = $app->user;
                        if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
                            return 1;
                        }
                    }
                }
                return 0;
            },
        },
    }
}

sub _html_category_at_mailpost {
    my ( $prop, $obj ) = @_;
    my $app = MT->instance;
    my $blog = $app->blog;
    return '-' unless $blog;
    my $blog_id = $blog->id;
    my $perm = MT->model( 'permission' )->load( { author_id => $obj->id,
                                                  blog_id => $blog_id,
                                                }
                                              );
    return '-' unless $perm;
    return '-' unless $blog->allow_mailpost();
    my $plugin = MT->component( 'Mobile' );
    my $show_link = is_user_can( $blog, $obj, 'create_post' ) ? 1 : 0;
    my $text = '-';
    if ( my $category_ids = $perm->mobile_categories ) {
        my @ids = split( /,/, $category_ids );
        my @cats = MT->model( 'category' )->load( { id => \@ids,
                                                    blog_id => $blog_id,
                                                  }
                                                );
        if ( @cats ) {
            my @labels;
            for my $c ( @cats ) {
                push ( @labels, MT::Util::encode_html( $c->label ) );
            }
            $text = join( ',', @labels );
        }
    }
    if ( $show_link ) {
        if ( $text eq '-' ) {
            $text = '<img src="' . MT->static_path . 'images/status_icons/create.gif" width="9" height="9" alt="' . $plugin->translate( 'Add category at mailpost' ) . '" title="' . $plugin->translate( 'Add category at mailpost' ) . '" />';
        }
        my $edit_link = $app->uri(
            mode => 'manage_category_at_mailpost',
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
    return $text || '-';
}

1;