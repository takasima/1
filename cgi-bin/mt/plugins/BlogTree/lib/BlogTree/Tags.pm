package BlogTree::Tags;
use strict;

use MT::I18N qw( substr_text length_text );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_cms current_user current_blog is_user_can );

our $plugin = MT->component( 'BlogTree' );

sub _hdlr_assets {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $args->{ blog_id }
                    ? MT::Blog->load( { id => $args->{ blog_id } } )
                    : $ctx->stash( 'blog' );
    return '' unless $blog;
    my $blog_id = $blog->id;
    my $folder_id = $args->{ folder_id };
    if ( $folder_id ) {
        my $exists = MT->model( 'folder' )->count( { id => $folder_id } );
        return '' unless $exists;
    }
    my $class = $args->{ class } || '*';
    my $limit = $args->{ limit } || 9999;
    my $offset = $args->{ offset } || 0;
    my $sort_by = $args->{ sort_by } || 'modified_on';
    my $sort_order = $args->{ sort_order } || 'descend';
    if ( my $lastn = $args->{ lastn } ) {
        $sort_by = 'modified_on';
        $limit = $lastn;
    }
    my $terms = { blog_id => $blog_id,
                  class => $class,
                };
    $args = { 'sort' => $sort_by,
                 direction => $sort_order,
                 limit => $limit,
                 offset => $offset,
                 direction => $sort_order,
               };
    if ( $folder_id ) {
       $args->{ 'join' } = MT->model( 'objectfolder' )->join_on( 'object_id',
                                                                 { folder_id => $folder_id,
                                                                   object_ds => 'asset',
                                                                 },
                                                               );
    } else {
        $args->{ 'join' } = MT->model( 'objectfolder' )->join_on( undef,
                                                                  { id => \'is null' },
                                                                  {
                                                                    type => 'left',
                                                                    condition => {
                                                                       object_ds => 'asset',
                                                                       object_id => \'= asset_id',
                                                                    },
                                                                  },
                                                                );
    }
    my @assets = MT->model( 'asset' )->load( $terms, $args );
    if ( @assets ) {
        my $vars = $ctx->{ __stash }{ vars } ||= {};
        my $res = '';
        my $i = 0;
        for my $asset ( @assets ) {
            local $ctx->{ __stash }{ 'asset' } = $asset;
            local $ctx->{ __stash }{ 'blog' } = $asset->blog;
            local $ctx->{ __stash }{ 'blog_id' } = $asset->blog_id;
            local $vars->{ __first__ } = !$i;
            local $vars->{ __last__ } = !defined $assets[ $i + 1 ];
            local $vars->{ __odd__ } = ( $i % 2 ) == 0;
            local $vars->{ __even__ } = ( $i % 2 ) == 1;
            local $vars->{ __counter__ } = $i + 1;
            my $out = $builder->build( $ctx, $tokens, {
                    %$cond,
                    'blogtreeassetsheader' => !$i,
                    'blogtreeassetsfooter' => !defined $assets[ $i + 1 ],
                } );
            $res .= $out;
            $i++;
        }
        return $res;
    } else {
        return $ctx->_hdlr_pass_tokens_else( @_ );
    }
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_if_user_has_perm {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = $args->{ blog_id };
    unless ( defined $blog_id ) {
        my $blog = $ctx->stash( 'blog' );
        $blog_id = $blog->id;
    }
    return 0 unless $blog_id;
    my $author;
    if ( my $author_id = $args->{ author_id } ) {
        $author = MT->model( 'author' )->load( { id => $author_id } );
    } elsif ( is_cms( MT->instance ) ) {
        my $app = MT->instance;
        $author = current_user( $app );
    }
    if ( $author ) {
        return $author->has_perm( $blog_id );
    }
    return 0;
}

sub _hdlr_if_child_blog {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $blog = $ctx->stash( 'blog' ) ) {
        my $blog_id = $blog->id;
        if ( my $website_id = $args->{ website_id } ) {
            if ( my $children = $blog->blogs ) {
                return grep { $_->id =~ $blog_id } @$children;
            }
        }
    }
    return 0;
}

sub _staticfullurl {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $static_uri = $app->static_path;
    if ( $static_uri !~ /^http/ ) {
        $static_uri = $app->base . $static_uri;
    }
    if ( $static_uri !~ m!/$! ) {
        $static_uri .= '/';
    }
    return $static_uri;
}

sub _adminfullurl {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $mt_uri = $app->mt_uri;
    if ( $mt_uri !~ /^http/ ) {
        $mt_uri = $app->base . $mt_uri;
    }
    return $mt_uri;
}

sub _fltr_trim_to {
    my ( $str, $val, $ctx ) = @_;
    return '' if $val <= 0;
    my $org = $str;
    $str = substr_text( $str, 0, $val ) if $val < length_text( $str );
    $str .= '...' if ( $org ne $str );
    return $str;
}

sub _blogtree_entries_lastn {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    return $plugin->get_config_value( 'entries_lastn', 'blog:'. $blog->id );
}

sub _blogtree_cat_depth {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    return $plugin->get_config_value( 'max_depth', 'blog:'. $blog->id );
}

sub _blogtree_cat_display {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    return $plugin->get_config_value( 'max_display', 'blog:'. $blog->id );
}

sub _blogtree_blogname_trim {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    return $plugin->get_config_value( 'blog_name_trim', 'blog:'. $blog->id );
}

sub _blogtree_entrytitle_trim {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    return $plugin->get_config_value( 'entry_title_trim', 'blog:'. $blog->id );
}

sub _hdlr_blog_ctx {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    if ( my $blog = current_blog( $app ) ) {
        my $tokens = $ctx->stash( 'tokens' );
        my $builder = $ctx->stash( 'builder' );
        local $ctx->{ __stash }{ 'blog' } = $blog;
        local $ctx->{ __stash }{ 'blog_id' } = $blog->id;
        my $out = $builder->build( $ctx, $tokens, $cond );
        return $out;
    }
    return '';
}

sub _hdlr_is_superuser {
    my $app = MT->instance;
    return $app->user->is_superuser();
}

sub _hdlr_can_create_page {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $user = current_user( $app );
    my $blog = $ctx->stash( 'blog' );
    return is_user_can( $blog, $user, 'manage_pages' );
}

sub _hdlr_can_create_entry {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $user = current_user( $app );
    my $blog = $ctx->stash( 'blog' );
    return is_user_can( $blog, $user, 'create_post' );
}

sub _hdlr_is_toplevel {
    my ( $ctx, $args, $cond ) = @_;
    my $category = $ctx->stash( 'category' );
    if ( $category->parent ) {
        return 0;
    }
    return 1;
}

sub _hdlr_entry_status_num {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' );
    return $entry->status;
}

sub _hdlr_blog_entry_count {
    my ( $ctx, $args, $cond ) = @_;
    my $class_type = $args->{ class_type } || 'entry';
    my $class = MT->model( $class_type );
    my ( %terms, %args );
    $ctx->set_blog_load_context( $args, \%terms, \%args ) or return $ctx->error( $ctx->errstr );
    my $blog = $ctx->stash( 'blog' );
    my $status = $args->{ status };
    my $primary = $args->{ primary };
    if ( $status ) {
        $terms{ 'status' } = $status;
    }
    my $status_not = $args->{ status_not };
    if ( $status_not ) {
        $terms{ 'status' } = { not => $status_not };
    }
    my $isolation = $args->{ isolation };
    if ( $isolation ) {
        $args{ 'join' } = MT->model( 'placement' )->join_on( undef,
                                                                 { id => \'is null', },
                                                                 { type => 'left',
                                                                   condition => {
                                                                       entry_id => \'= entry_id',
                                                                   },
                                                                 },
                                                               );
    }
    require MT::Placement;
    my $category_id = $args->{ category_id };
    if ( $category_id ) {
        if ( $primary ) {
            $args{ 'join' } = [ 'MT::Placement',
                                'entry_id',
                                { blog_id => $blog->id,
                                  is_primary => 1,
                                  category_id => $category_id,
                                }, { 
                                  unique => 1,
                                }
                              ];
        } else {
            $args{ 'join' } = [ 'MT::Placement',
                                'entry_id',
                                { blog_id => $blog->id,
                                  category_id => $category_id,
                                }, {
                                  unique => 1,
                                }
                              ];
        }
    }
    if ( $blog->class eq 'website' ) {
        if ( $args->{ include_blogs } eq 'children' ) {
            my $children = $blog->blogs;
            my @blog_ids = map { $_->id; } @$children;
            push( @blog_ids, $blog->id );
            $terms{ 'blog_id' } = \@blog_ids;
        }
    }
    my $count = $class->count( \%terms, \%args );
    return $ctx->count_format( $count, $args );
}

sub _hdlr_blog_tag_count {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $iter = MT->model( 'objecttag' )->count_group_by( { blog_id => $blog->id },
                                                         { group => ['tag_id'] }
                                                       );
    my $i = 0;
    while ( my ( $count, $cat ) = $iter->() ) {
        $i++;
    }
    return $i;
}

sub _hdlr_blog_folder_count {
    my ( $ctx, $args, $cond ) = @_;
    my ( %terms, %args );
    $ctx->set_blog_load_context( $args, \%terms, \%args ) or return $ctx->error( $ctx->errstr );
    my $count = MT->model( 'folder' )->count( \%terms, \%args );
    return $ctx->count_format( $count, $args );
}

sub _hdlr_blog_comment_count {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $junk_status = $args->{ junk_status };
    my $visible = $args->{ visible };
    my $terms = { blog_id => $blog->id };
    if ( $junk_status ) {
        $terms->{ 'junk_status' } = $junk_status;
    }
    if ( defined $visible ) {
        $terms->{ 'visible' } = $visible;
        if ( $visible eq '0' ) {
            $terms->{ 'visible' } = 0;
        }
    }
    if ( $blog->class eq 'website' ) {
        if ( $args->{ include_blogs } eq 'children' ) {
            my $children = $blog->blogs;
            my @blog_ids = map { $_->id; } @$children;
            push( @blog_ids, $blog->id );
            $terms->{ 'blog_id' } = \@blog_ids;
        }
    }
    my $count = MT->model( 'comment' )->count( $terms );
    return $count if $count;
    return 0;
}

sub _hdlr_blog_ping_count {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $junk_status = $args->{ junk_status };
    my $visible = $args->{ visible };
    my $terms = { blog_id => $blog->id };
    if ( $junk_status ) {
        $terms->{ 'junk_status' } = $junk_status;
    }
    if ( $visible ) {
        $terms->{ 'visible' } = $visible;
    }
    if ( $visible eq '0' ) {
        $terms->{ 'visible' } = 0;
    }
    if ( $blog->class eq 'website' ) {
        if ( $args->{ include_blogs } eq 'children' ) {
            my $children = $blog->blogs;
            my @blog_ids = map { $_->id; } @$children;
            push( @blog_ids, $blog->id );
            $terms->{ 'blog_id' } = \@blog_ids;
        }
    }
    my $count = MT->model( 'tbping' )->count( $terms );
    return $count || 0;
}

sub _hdlr_blog_form_count {
    my ( $ctx, $args, $cond ) = @_;
    my $model;
    if ( MT->component( 'ContactForm' ) ) {
        $model = 'feedback';
    } elsif ( MT->component( 'ExtraForm' ) ) {
        $model = 'extraform';
    }
    if ( $model ) {
        my $blog = $ctx->stash( 'blog' );
        my $status = $args->{ status };
        my $terms = { blog_id => $blog->id };
        if ( $status ) {
            $terms->{ 'status' } = $status;
        }
        if ( $blog->class eq 'website' ) {
            if ( $args->{ include_blogs } eq 'children' ) {
                my $children = $blog->blogs;
                my @blog_ids = map { $_->id; } @$children;
                push( @blog_ids, $blog->id );
                $terms->{ 'blog_id' } = \@blog_ids;
            }
        }
        my $count = MT->model( $model )->count( $terms );
        return $count || 0;
    }
    return 0;
}

sub _hdlr_entries {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Placement;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $ctx->stash( 'blog' );
    my $class = $args->{ class } || 'entry';
    my $lastn = $args->{ lastn };
    my $limit = $args->{ limit };
    my $offset = $args->{ offset };
    my $primary = $args->{ primary };
    my $terms = { blog_id => $blog->id,
                  class => $class,
                };
    my $status = $args->{ status };
    if ( $status ) {
        $terms->{ 'status' } = $status;
    }
    my $status_not = $args->{ status_not };
    if ( $status_not ) {
        $terms->{ 'status' } = { 'not' => $status_not };
    }
    my $params = { 'sort' => 'authored_on',
                   direction => 'descend',
                 };
    my $category_id = $args->{ category_id };
    if ( $category_id ) {
        if ( $primary ) {
            $params->{ 'join' } = [ 'MT::Placement',
                                    'entry_id',
                                    { blog_id => $blog->id,
                                      category_id => $category_id,
                                      is_primary  => 1,
                                    }, {
                                      unique => 1,
                                    }
                                  ];
        } else {
            $params->{ 'join' } = [ 'MT::Placement',
                                    'entry_id',
                                    { blog_id => $blog->id,
                                      category_id => $category_id,
                                    }, {
                                      unique => 1,
                                    }
                                  ];
        }
    }
    if( $limit ) {
        $lastn = $limit;
    }
    if ( $lastn ) {
        $params->{ limit } = $lastn;
    }
    if ( $offset ) {
        $params->{ offset } = $offset;
    }
    my $isolation = $args->{ isolation };
    if ( $isolation ) {
        $params->{ 'join' } = MT->model( 'placement' )->join_on( undef,
                                                                 { id => \'is null', },
                                                                 { type => 'left',
                                                                   condition => {
                                                                       entry_id => \'= entry_id',
                                                                   },
                                                                 },
                                                               );
    }
    $class = MT->model( $class );
    my @entries = $class->load ( $terms, $params );
    my $vars = $ctx->{ __stash }{vars} ||= {};
    my $res = '';
    my $i = 0;
    for my $entry ( @entries ) {
        local $ctx->{ __stash }{ 'entry' } = $entry;
        local $ctx->{ __stash }{ 'page' }  = $entry;
        local $ctx->{ __stash }{ 'blog' } = $entry->blog;
        local $vars->{ __counter__ } = $i + 1;
        my $out = $builder->build( $ctx, $tokens, {
                %$cond,
                lc ( 'BlogTreeEntriesHeader' ) => $i == 0,
                lc ( 'BlogTreeEntriesFooter' ) => !defined( $entries[ $i + 1 ] ),
            } );
        $res .= $out;
        $i++;
    }
    $res;
}

sub _remove_return {
    my ( $ctx, $args, $cond ) = @_;
    my $res = $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
    if ( $res =~ m!\n! ) {
        $res =~ s!\n!!g;
    }
    $res;
}

sub _hdlr_is_published {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' );
    if ( $entry->status == MT::Entry::RELEASE() ) {
        return 1;
    }
    return 0;
}



sub _hdlr_if_blogtree {
    my ( $ctx, $args, $cond ) = @_;
    return __is_blogtree( MT->instance() );
}

sub __is_blogtree {
    my $app = shift;
    my $r = MT::Request->instance;
    my $is_blogtree = $r->cache( 'powercms_is_blogtree' );
    if ( $is_blogtree ) {
        if ( $is_blogtree eq 'true' ) {
            return 1;
        } elsif ( $is_blogtree eq 'false' ) {
            return 0;
        }
    }
    my $mode = $app->mode; my $view = $app->view; my $user = current_user( $app ) || return 0;
    my $bt;
    if ( $mode ne 'blogtree' ) {
        if ( $view eq 'user' || $mode eq 'default' || $mode eq 'dashboard' ) {
            my $widget_store = $user->widgets;
            if ( my $blog = $app->blog ) {
                my $blog_id = $blog->id;
                my $widgets = $widget_store->{ "dashboard:blog:$blog_id" } if $widget_store;
                $bt = $widgets->{ blog_tree } if $widgets;
            } else {
                my $user_id = $user->id;
                my $widgets = $widget_store->{ "dashboard:$view:$user_id" } if $widget_store;
                $bt = $widgets->{ blog_tree } if $widgets;
            }
        }
    } else {
        $bt = 1;
    }
    if ( $bt ) { $r->cache( 'powercms_is_blogtree', 'true' ); } else { $r->cache( 'powercms_is_blogtree', 'false' ); }
    return $bt;
}


sub _blogtreedashboardcss {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'powercms_blogtreedashboardcss' );
    return $cache if $cache;
    my $static_path = $app->static_path;
    my $src = '';
    my $user = $app->user;
    my $user_id = $user->id;
    my $bt = __is_blogtree( $app );
    if (! $bt ) { return $src; }
    $src .= '<style type="text/css">' . "\n";
    my $blog_ids;
    if ( my $blog = $app->blog ) {
        $blog_ids = get_weblog_ids( $blog );
    } else {
        $blog_ids = get_weblog_ids();
    }
    for my $blog_id ( @$blog_ids ) {
        my $perms;
        $perms = $r->cache( 'blog_author_permission:' . $blog_id );
        if (! $perms ) {
            $perms = $user->permissions( $blog_id );
            if (! $perms ) {
                $perms = MT->model( 'permission' )->load( { blog_id => $blog_id,
                                                            author_id => $user->id,
                                                          }
                                                        );
            }
            $r->cache( 'blog_author_permission:' . $blog_id, $perms );
        }
        my $blog = MT::Blog->load( { id => $blog_id } );
        my $admin = is_user_can( $blog, $user, 'administer_blog' );
        my $edit_all_posts = is_user_can( $blog, $user, 'edit_all_posts' );
        my $publish_post = is_user_can( $blog, $user, 'publish_post' );
        my $create_post = is_user_can( $blog, $user, 'create_post' );
        my $manage_pages = is_user_can( $blog, $user, 'manage_pages' );
        my $edit_categories = is_user_can( $blog, $user, 'edit_categories' );
        my $edit_templates = is_user_can( $blog, $user, 'edit_templates' );
if ( $admin ) {
$src .= <<CSS
#bt-body-$blog_id .setting { display:inline }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id .setting { display:none }
CSS
}
if ( $edit_categories ) {
$src .= <<CSS
#bt-body-$blog_id .home .edit.edit-category { display:inline }
#bt-body-$blog_id #tree_$blog_id .category > .meta .edit { display:inline }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id .home .edit.edit-category { display:none }
#bt-body-$blog_id #tree_$blog_id .category > .meta .edit { display:none }
CSS
}
if (! $edit_templates ) {
$src .= <<CSS
#bt-body-$blog_id .home .list-template { display:none }
CSS
}
if (! $create_post ) {
$src .= <<CSS
/*not_create_post*/
#bt-body-$blog_id .home .edit { display:none }
#bt-body-$blog_id #tree_$blog_id li > .meta .edit { display:none }
#bt-body-$blog_id #tree_$blog_id li > .meta .duplicate { display:none }
#bt-body-$blog_id #tree_$blog_id li > .meta .new { display:none }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id .home .edit.edit-entry { display:inline }
#bt-body-$blog_id #tree_$blog_id .category > .meta .new { display:inline }
CSS
}
if ( (! $edit_all_posts) && ( $create_post ) ) {
if (! $publish_post ) {
$src .= <<CSS
#bt-body-$blog_id #tree_$blog_id .entry > .meta .edit { display:none }
#bt-body-$blog_id #tree_$blog_id .entry.author-$user_id.status-draft > .meta .edit { display:inline !important; }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id #tree_$blog_id .entry > .meta .edit { display:none }
#bt-body-$blog_id #tree_$blog_id .entry.author-$user_id.status-draft > .meta .edit { display:inline !important; }
#bt-body-$blog_id #tree_$blog_id .entry.author-$user_id.status-release > .meta .edit { display:inline !important; }
CSS
}
}
if ( $edit_all_posts )  {
if ( $publish_post ) {
$src .= <<CSS
#bt-body-$blog_id #tree_$blog_id .entry > .meta .edit { display:inline }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id #tree_$blog_id .entry > .meta .edit { display:inline }
#bt-body-$blog_id #tree_$blog_id .entry.status-release > .meta .edit { display:none !important; }
#bt-body-$blog_id #tree_$blog_id .entry.approval > .meta .edit { display:none !important; }
CSS
}
}

if( $manage_pages ) {
$src .= <<CSS
#bt-body-$blog_id .home .edit.edit-folder { display:inline }
#bt-body-$blog_id .home .edit.edit-page { display:inline }
#bt-body-$blog_id #tree_$blog_id .folder > .meta .new { display:inline }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id .home .edit.edit-folder { display:none }
#bt-body-$blog_id .home .edit.edit-page { display:none }
#bt-body-$blog_id #tree_$blog_id .folder > .meta .new { display:none }
#bt-body-$blog_id #tree_$blog_id .page > .meta .duplicate { display:none }
CSS
}
if ( ( $manage_pages ) && ( $publish_post ) ) {
$src .= <<CSS
#bt-body-$blog_id #tree_$blog_id .page > .meta .edit { display:inline }
#bt-body-$blog_id #tree_$blog_id .folder > .meta .edit { display:inline }
CSS
} else {
$src .= <<CSS
#bt-body-$blog_id #tree_$blog_id .page > .meta .edit { display:none }
#bt-body-$blog_id #tree_$blog_id .folder > .meta .edit { display:none }
CSS
}
}
$src .= '</style>';
#if ( MT->config->CSSCompressor ) {
    require CSS::Minifier;
    $src = CSS::Minifier::minify( input => $src );
#}
$r->cache( 'powercms_blogtreedashboardcss', $src );
return $src;
}

sub get_weblog_ids {
    my $website = shift;
    my $plugin = MT->component( 'BlogTree' );
    my $app = MT->instance();
    if ( $website && ( $website->class eq 'blog' ) ) {
        $website = $website->website;
    }
    my $r = MT::Request->instance();
    my $blog_ids;
    my $cache;
    if ( $website ) {
        $blog_ids = $r->cache( 'powercms_get_weblog_ids_blog:' . $website->id );
        $cache = $plugin->get_config_value( 'get_weblog_ids_cache', 'blog:'. $website->id );
    } else {
        $blog_ids = $r->cache( 'powercms_get_weblog_ids_system' );
        $cache = $plugin->get_config_value( 'get_weblog_ids_cache' );
    }
    return $blog_ids if $blog_ids;
    if ( $cache ) {
        @$blog_ids = split( /,/, $cache );
        return $blog_ids;
    }
    my $weblogs;
    if (! $website ) {
        $weblogs = $r->cache( 'powercms_all_weblogs' );
        if (! $weblogs ) {
            @$weblogs = MT::Blog->load( { class => '*' } );
            $r->cache( 'powercms_all_weblogs', $weblogs );
        }
    } else {
        @$weblogs = get_weblogs( $website );
    }
    for my $blog ( @$weblogs ) {
        push ( @$blog_ids, $blog->id );
    }
    if ( $website ) {
        $r->cache( 'powercms_get_weblog_ids_blog:' . $website->id, $blog_ids );
        $plugin->set_config_value( 'get_weblog_ids_cache', join ( ',', @$blog_ids ), 'blog:'. $website->id );
    } else {
        $r->cache( 'powercms_get_weblog_ids_system', $blog_ids );
        $plugin->set_config_value( 'get_weblog_ids_cache', join ( ',', @$blog_ids ) );
    }
#     if ( wantarray ) {
#         return @$blog_ids;
#     }
    return $blog_ids;
}

sub get_weblogs {
    my $blog = shift;
    my @blogs;
    if ( MT->version_number < 5 ) {
        push ( @blogs, $blog );
        return @blogs;
    }
    push ( @blogs, $blog );
    if ( $blog->class eq 'website' ) {
        my $weblogs = $blog->blogs || [];
        push ( @blogs, @$weblogs );
    }
    return @blogs;
}

sub _is_create_post {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $static_path = $app->static_path;
    my $user = current_user( $app );
    my $user_id = $user->id;
    my $blogs;
    my $bt = __is_blogtree( $app );
    if (! $bt ) { return ''; }
    require MT::Blog;
    my $r = MT::Request->instance;
    if ( $app->blog ) {
        push ( @$blogs, $app->blog );
        if ( $app->blog->class eq 'website' ) {
            my $children = $app->blog->blogs;
            push ( @$blogs, @$children );
        }
    } else {
        $blogs = $r->cache( 'blogtree_blogs' );
        if (! $blogs ) {
            require ItemGroup::ItemGroup;
            require ItemGroup::ItemOrder;
            my $group = ItemGroup::ItemGroup->load( { object_ds => 'blog',
                                                      name => 'BlogTree',
                                                    }
                                                  );
            if ( defined $group ) {
                my $terms = { class => '*' };
                my $params = { 'join' => [ 'ItemGroup::ItemOrder',
                                           'object_id',
                                           { itemgroup_id => $group->id, },
                                           { 'sort' => 'number',
                                             direction => 'ascend',
                                           }
                                         ]
                             };
                @$blogs = MT::Blog->load( $terms, $params );
            } else {
                @$blogs = MT::Blog->load( { class => '*' } );
            }
        }
        $r->cache( 'blogtree_blogs', $blogs );
    }
    my $src = "";
    $src .= '<script type="text/javascript">' . "\n";
    $src .= 'var blog_posts = new Array();' . "\n";
    $src .= 'var blog_pages = new Array();' . "\n";
    for my $blog ( @$blogs ) {
        my $blog_id = $blog->id;
        my $perms;
        $perms = $r->cache( 'blog_author_permission:' . $blog_id );
        if (! $perms ) {
            $perms = $user->permissions( $blog_id );
            if (! $perms ) {
                $perms = MT->model( 'permission' )->load( { blog_id => $blog_id,
                                                            author_id => $user->id,
                                                          }
                                                        );
            }
            $r->cache( 'blog_author_permission:' . $blog_id, $perms );
        }
        my $admin = is_user_can( $blog, $user, 'administer_blog' );
        my $publish_post = is_user_can( $blog, $user, 'publish_post' );
        my $create_post = is_user_can( $blog, $user, 'create_post' );
        my $manage_pages = is_user_can( $blog, $user, 'manage_pages' );
        if ( $publish_post || $create_post ) {
            $src .= 'blog_posts[' . $blog->id . ']=true;' . "\n";
        }
        if ( $manage_pages ) {
            $src .= 'blog_pages[' . $blog->id . ']=true;' . "\n";
        }
    }
    $src .= '</script>';
    return $src;
}


1;