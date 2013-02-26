package Mobile::CMS;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can );

sub _mode_manage_category_at_mailpost {
    my $app = shift;
    my $plugin = MT->component( 'Mobile' );
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $blog = $app->blog or return $app->trans_error( 'Invalid request.' );
    unless ( $blog->is_blog ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $user = $app->user;
    if (! is_user_can( $blog, $user, 'administer_blog' ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog_id = $blog->id;
    my @categories;
    if ( my @category_ids = $app->param( 'category_id' ) ) {
        @categories = MT->model( 'category' )->load( { id => \@category_ids } );
        for my $cat ( @categories ) {
            if ( $blog_id != $cat->blog_id ) {
                return $app->trans_error( 'Invalid request.' );
            }
            if ( $cat->class ne 'category' ) {
                return $app->trans_error( 'Invalid request.' );
            }
        }
    }
    my $id = $app->param( 'author_id' ) or return $app->trans_error( 'Invalid request.' );
    my $author = MT->model( 'author' )->load( $id ) or return $app->trans_error( 'Invalid request.' );
    if (! is_user_can( $blog, $author, 'create_post' ) ) {
        return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
    }
    my $perm = MT->model( 'permission' )->load( { blog_id => $blog->id,
                                                  author_id => $author->id,
                                                }
                                              );
    if (! $perm ) {
        return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
    }
    my %param;
    $param{ selected_user_loop } = [ { author_name => $author->name } ];
    my $categories = $perm->mobile_categories;
    my @can_post;
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'update' ) {
        my $changed;
        for my $cat ( @categories ) {
            my $cid = $cat->id;
            if ( ! @can_post || (! grep( /^$cid$/, @can_post ) ) ) {
                push( @can_post, $cid );
                $changed = 1;
            }
        }
        if (! scalar( @categories ) && $categories ) {
            $changed = 1;
        }
        if ( $changed ) {
            $perm->mobile_categories( join( ',', @can_post ) );
            $perm->save or die $perm->errstr;
        }
    } else {
        if ( $categories ) {
            @can_post = split( /,/, $categories );
        }
        my $data = $app->_build_category_list(
            blog_id => $blog_id,
            markers => 1,
            type    => 'category',
        );
        my $cat_tree = [];
        foreach ( @$data ) {
            next unless exists $_->{ category_id };
            $_->{ category_path_ids } ||= [];
            unshift @{ $_->{ category_path_ids } }, -1;
            my $current_id = $_->{ category_id };
            my $has_perm = grep( /^$current_id$/, @can_post ) ? 1 : 0;
            push @$cat_tree, { category_id => $_->{ category_id },
                               has_perm => $has_perm,
                               category_label_spacer => '&nbsp;&nbsp;' . ( $_->{ category_label_spacer } x 2 ),
                               category_label => $_->{ category_label },
                               category_basename => $_->{ category_basename },
                               category_path => $_->{ category_path_ids } || [],
                               category_fields => $_->{ category_fields } || [],
                             };
        }
        $param{ id } = $id;
        $param{ category_tree } = $cat_tree;
        $param{ action } = 'update';
    }
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    my $tmpl = 'category_table.tmpl';
    return $app->build_page( $tmpl, \%param );
}

sub _mode_add_category_at_mailpost {
    my $app = shift;
    my $plugin = MT->component( 'Mobile' );
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $blog = $app->blog or return $app->trans_error( 'Invalid request.' );
    unless ( $blog->is_blog ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $user = $app->user;
    if (! is_user_can( $blog, $user, 'administer_blog' ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog_id = $blog->id;
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'add' ) {
        my $author_ids = $app->param( 'ids' );
        @ids = split( /,/, $author_ids );
    }
    my @categories;
    if ( my @category_ids = $app->param( 'category_id' ) ) {
        @categories = MT->model( 'category' )->load( { id => \@category_ids } );
        for my $cat ( @categories ) {
            if ( $blog_id != $cat->blog_id ) {
                return $app->trans_error( 'Invalid request.' );
            }
            if ( $cat->class ne 'category' ) {
                return $app->trans_error( 'Invalid request.' );
            }
        }
    }
    my $single_select = ( scalar @ids == 1 ) ? 1 : 0;
    my @selected_user;
    my @single_can_post;
    for my $id ( @ids ) {
        my $author = MT->model( 'author' )->load( $id ) or return $app->trans_error( 'Invalid request.' );
        if (! is_user_can( $blog, $author, 'create_post' ) ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        my $perm = MT->model( 'permission' )->load( { blog_id => $blog->id,
                                                      author_id => $author->id,
                                                    }
                                                  );
        if (! $perm ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        push ( @selected_user, { author_name => $author->name } );
        my $categories = $perm->mobile_categories;
        my @can_post;
        if ( $categories ) {
            @can_post = split( /,/, $categories );
        }
        @single_can_post = @can_post;
        if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'add' ) {
            my $changed;
            for my $cat ( @categories ) {
                my $cid = $cat->id;
                if ( ! @can_post || (! grep( /^$cid$/, @can_post ) ) ) {
                    push( @can_post, $cid );
                    $changed = 1;
                }
            }
            if ( $changed ) {
                $perm->mobile_categories( join( ',', @can_post ) );
                $perm->save or die $perm->errstr;
            }
        }
    }
    my %param;
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'add' ) {
    } else {
        my $data = $app->_build_category_list(
            blog_id => $blog_id,
            markers => 1,
            type    => 'category',
        );
        my $cat_tree = [];
        foreach ( @$data ) {
            next unless exists $_->{ category_id };
            $_->{ category_path_ids } ||= [];
            unshift @{ $_->{ category_path_ids } }, -1;
            my $current_id = $_->{ category_id };
            my $has_perm;
            if ( $single_select ) {
                if ( grep( /^$current_id$/, @single_can_post ) ) {
                    $has_perm = 1;
                }
            }
            push @$cat_tree, { category_id => $_->{ category_id },
                               has_perm => $has_perm,
                               category_label_spacer => '&nbsp;&nbsp;' . ( $_->{ category_label_spacer } x 2 ),
                               category_label => $_->{ category_label },
                               category_basename => $_->{ category_basename },
                               category_path => $_->{ category_path_ids } || [],
                               category_fields => $_->{ category_fields } || [],
                             };
        }
        $param{ ids } = join( ',', @ids );
        $param{ category_tree } = $cat_tree;
        $param{ action } = 'add';
    }
    $param{ selected_user_loop } = \@selected_user;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    my $tmpl = 'category_table.tmpl';
    return $app->build_page( $tmpl, \%param );
}

sub _mode_remove_category_at_mailpost {
    my $app = shift;
    my $plugin = MT->component( 'Mobile' );
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $blog = $app->blog or return $app->trans_error( 'Invalid request.' );
    unless ( $blog->is_blog ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $user = $app->user;
    if (! is_user_can( $blog, $user, 'administer_blog' ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog_id = $blog->id;
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'remove' ) {
        my $author_ids = $app->param( 'ids' );
        @ids = split( /,/, $author_ids );
    }
    my @categories;
    my @category_ids = $app->param( 'category_id' );
    if ( @category_ids ) {
        @categories = MT->model( 'category' )->load( { id => \@category_ids } );
        for my $cat ( @categories ) {
            if ( $blog_id != $cat->blog_id ) {
                return $app->trans_error( 'Invalid request.' );
            }
            if ( $cat->class ne 'category' ) {
                return $app->trans_error( 'Invalid request.' );
            }
        }
    }
    my $single_select = ( scalar @ids == 1 ) ? 1 : 0;
    my @selected_user;
    my @single_can_post;
    for my $id ( @ids ) {
        my $author = MT->model( 'author' )->load( $id );
        if (! $author ) {
            return $app->trans_error( 'Invalid request.' );
        }
        if (! is_user_can( $blog, $author, 'create_post' ) ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        my $perm = MT->model( 'permission' )->load( { blog_id => $blog->id,
                                                      author_id => $author->id,
                                                    }
                                                  );
        if (! $perm ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        push ( @selected_user, { author_name => $author->name } );
        my $categories = $perm->mobile_categories;
        my @can_post;
        if ( $categories ) {
            @can_post = split( /,/, $categories );
        }
        @single_can_post = @can_post;
        if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'remove' ) {
            my $changed;
            my @can_post_new;
            if ( @can_post ) {
                for my $cid ( @can_post ) {
                    if (! grep( /^$cid$/, @category_ids ) ) {
                        push ( @can_post_new, $cid );
                    } else {
                        $changed = 1;
                    }
                }
            }
            if ( $changed ) {
                $perm->mobile_categories( join( ',', @can_post_new ) );
                $perm->save or die $perm->errstr;
            }
        }
    }
    my %param;
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'remove' ) {
    } else {
        my $data = $app->_build_category_list(
            blog_id => $blog_id,
            markers => 1,
            type    => 'category',
        );
        my $cat_tree = [];
        foreach ( @$data ) {
            next unless exists $_->{ category_id };
            $_->{ category_path_ids } ||= [];
            unshift @{ $_->{ category_path_ids } }, -1;
            my $current_id = $_->{ category_id };
            my $has_perm;
            if ( $single_select ) {
                if ( grep( /^$current_id$/, @single_can_post ) ) {
                    $has_perm = 1;
                }
            }
            push @$cat_tree, { category_id => $_->{ category_id },
                               has_perm => $has_perm,
                               category_label_spacer => '&nbsp;&nbsp;' . ( $_->{ category_label_spacer } x 2 ),
                               category_label => $_->{ category_label },
                               category_basename => $_->{ category_basename },
                               category_path => $_->{ category_path_ids } || [],
                               category_fields => $_->{ category_fields } || [],
                             };
        }
        $param{ ids } = join( ',', @ids );
        $param{ category_tree } = $cat_tree;
        $param{ action } = 'remove';
    }
    $param{ selected_user_loop } = \@selected_user;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    my $tmpl = 'category_table.tmpl';
    return $app->build_page( $tmpl, \%param );
}

1;
