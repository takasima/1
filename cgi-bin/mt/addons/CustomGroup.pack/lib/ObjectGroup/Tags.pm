package ObjectGroup::Tags;
use strict;

use ObjectGroup::ObjectGroup;
use ObjectGroup::ObjectOrder;
use PowerCMS::Util qw( get_weblog_ids );
use MT::Blog;
use MT::Category;
use MT::Entry;
use MT::Folder;
use MT::Page;

our $plugin_objectgroup = MT->component( 'ObjectGroup' );

sub _hdlr_og_groupitems {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $id = $args->{ id };
    my $name = $args->{ name } || $args->{ group };
    my $group_id = $args->{ group_id };
    if ( $group_id ) {
        $id = $group_id;
    }
    my $blog_id = $args->{ blog_id } || $ctx->stash( 'blog' )->id || 0;
    unless ( $id ) {
        if ( $app->isa( 'MT::App::CMS' ) && $app->mode eq 'objectgroup' ) {
            return '';
        }
        my $terms;
        $terms->{ name } = $name if $name;
        $terms->{ blog_id } = $blog_id if defined $blog_id;
        return '' unless $terms;
        my $group = ObjectGroup::ObjectGroup->load( $terms );
        $id = $group->id if defined $group;
        $blog_id = $group->blog_id if defined $group;
    }
    return '' unless $id;
    my $sort_order = $args->{ sort_order } || 'ascend';
    my $lastn = $args->{ limit } || $args->{ lastn } || 9999;
    my $count = ObjectGroup::ObjectOrder->count ( { objectgroup_id => $id },
                                                     { sort => 'number',
                                                       direction => $sort_order,
                                                       limit => $lastn }
                                                   );
    my $iter = ObjectGroup::ObjectOrder->load_iter ( { objectgroup_id => $id },
                                                     { sort => 'number',
                                                       direction => $sort_order,
                                                       limit => $lastn }
                                                   );
    my $res = '';
    my %blogs;
    my $odd = 1;
    my $i = 1;
    while ( my $order = $iter->() ) {
        my $object_ds = $order->object_ds;
        my $class = $order->class;
        my $id = $order->object_id;
        my $blog; my $category; my $entry;
        if ( $class eq 'blog' ) {
            $blog = MT::Blog->load( $id );
            if (! defined $blog ) {
                $order->remove;
                next;
            }
        } elsif ( $class eq 'website' ) {
            $blog = MT::Blog->load( $id );
            if (! defined $blog ) {
                $order->remove;
                next;
            }
        } elsif ( $class eq 'category' ) {
            $category = MT::Category->load( $id );
            if (! defined $category ) {
                $order->remove;
                next;
            }
            if ( $blogs{ 'blog_' . $category->blog_id } ) {
                $blog = $blogs{ 'blog_' . $category->blog_id };
            } else {
                $blog = MT::Blog->load( $category->blog_id );
            }
        } elsif ( $class eq 'folder' ) {
            $category = MT::Folder->load( $id );
            if (! defined $category ) {
                $order->remove;
                next;
            }
            if ( $blogs{ 'blog_' . $category->blog_id } ) {
                $blog = $blogs{ 'blog_' . $category->blog_id };
            } else {
                $blog = MT::Blog->load( $category->blog_id );
            }
        } elsif ( $class eq 'entry' ) {
            $entry = MT::Entry->load( $id );
            # $entry = MT::Entry->load( { id => $id,
            #                             status => MT::Entry::RELEASE(),
            #                           }
            #                         );
            if (! defined $entry ) {
                $order->remove;
                next;
            }
            if ( $entry->status != MT::Entry::RELEASE() ) {
                $entry = undef;
                next;
            }
            if ( $blogs{ 'blog_' . $entry->blog_id } ) {
                $blog = $blogs{ 'blog_' . $entry->blog_id };
            } else {
                $blog = $entry->blog;
            }
        } elsif ( $class eq 'page' ) {
            $entry = MT::Page->load( $id );
            # $entry = MT::Page->load( { id => $id,
            #                            status => MT::Entry::RELEASE(),
            #                          }
            #                        );
            if (! defined $entry ) {
                $order->remove;
                next;
            }
            if ( $entry->status != MT::Entry::RELEASE() ) {
                $entry = undef;
                next;
            }
            if ( $blogs{ 'blog_' . $entry->blog_id } ) {
                $blog = $blogs{ 'blog_' . $entry->blog_id };
            } else {
                $blog = $entry->blog;
            }
        }
        $blogs{ 'blog_' . $blog->id } = $blog if defined $blog;
        local $ctx->{ __stash }{ blog } = $blog;
        local $ctx->{ __stash }{ blog_id } = $blog->id if defined $blog;
        local $ctx->{ __stash }{ category } = $category;
        local $ctx->{ __stash }{ archive_category } = $category;
        local $ctx->{ __stash }{ entry } = $entry;
        local $ctx->{ __stash }{ object_ds } = $object_ds;
        local $ctx->{ __stash }{ class } = $class;
        local $ctx->{ __stash }{ vars }{ __counter__ } = $i;
        local $ctx->{ __stash }{ vars }{ __odd__ } = 1 if ( $odd );
        local $ctx->{ __stash }{ vars }{ __even__ } = 1 if (! $odd );
        local $ctx->{ __stash }{ vars }{ __first__ } = 1 if ( $i == 1 );
        local $ctx->{ __stash }{ vars }{ __last__ } = 1 if ( $count == $i );
        local $ctx->{ __stash }{ vars }{ __is_first__ } = 1 if ( $i == 1 );
        local $ctx->{ __stash }{ vars }{ __is_last__ } = 1 if ( $count == $i );
        local $ctx->{ __stash }{ vars }{ __class__ } = $class;
        my $out = $builder->build( $ctx, $tokens, $cond );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        $i++;
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
    }
    return $res;
}

sub _hdlr_og_groupitemclass {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'class' );
}

sub _hdlr_if_entry {
    my ( $ctx, $args, $cond ) = @_;
    my $object_ds = $ctx->stash( 'object_ds' );
    return $object_ds eq 'entry' ? 1 : 0;
}

sub _hdlr_if_category {
    my ( $ctx, $args, $cond ) = @_;
    my $object_ds = $ctx->stash( 'object_ds' );
    return $object_ds eq 'category' ? 1 : 0;
}

sub _hdlr_if_blog {
    my ( $ctx, $args, $cond ) = @_;
    my $object_ds = $ctx->stash( 'object_ds' );
    return $object_ds eq 'blog' ? 1 : 0;
}

sub _hdlr_og_entries {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $id = $app->param( 'id' );
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $terms;
    $terms->{ class } = [ 'entry', 'page' ];
    if ( my $blog_id = $args->{ blog_id } ) {
        $terms->{ blog_id } = $blog_id;
    } elsif ( $app->blog ) {
        if ( $app->blog->is_blog ) {
            $terms->{ blog_id } = $app->blog->id;
        } else {
            my $blog_ids = get_weblog_ids( $app->blog );
            $terms->{ blog_id } = $blog_ids;
        }
    }
    $terms->{ status } = { not => 7 };
    my $limit = defined $args->{limit} ? $args->{limit} : '1000';
    $limit = '1000' if $limit =~ /\D/;
    my $iter = MT::Entry->load_iter( $terms, { limit => $limit } );
    my $res;
    while ( my $e = $iter->() ) {
        my $order = ObjectGroup::ObjectOrder->load( { objectgroup_id => $id,
                                                      object_id => $e->id,
                                                      object_ds => 'entry' } ) if $id;
        next if ( $id && ( defined $order ) );
        local $ctx->{ __stash }{ blog } = $e->blog;
        local $ctx->{ __stash }{ blog_id } = $e->blog_id;
        local $ctx->{ __stash }{ entry } = $e;
        local $ctx->{ __stash }{ class } = $e->class;
        local $ctx->{ __stash }{ vars }{ __class__ } = $e->class;
        my $out = $builder->build( $ctx, $tokens, $cond );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
    }
    return $res;
}

sub _hdlr_og_categories {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $id = $app->param( 'id' );
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $terms;
    $terms->{ class } = '*';
    if ( my $blog_id = $args->{ blog_id } ) {
        $terms->{ blog_id } = $blog_id;
    } elsif ( $app->blog ) {
        if ( $app->blog->is_blog ) {
            $terms->{ blog_id } = $app->blog->id;
        } else {
            my $blog_ids = get_weblog_ids( $app->blog );
            $terms->{ blog_id } = $blog_ids;
        }
    }
    my $iter = MT::Category->load_iter( $terms, { limit => 1000 } );
    my $res;
    my %blogs;
    while ( my $c = $iter->() ) {
        my $order = ObjectGroup::ObjectOrder->load( { objectgroup_id => $id,
                                                      object_id => $c->id,
                                                      object_ds => 'category' } ) if $id;
        next if ( $id && ( defined $order ) );
        my $blog;
        if ( $blogs{ 'blog_' . $c->blog_id } ) {
            $blog = $blogs{ 'blog_' . $c->blog_id };
        } else {
            $blog = MT::Blog->load( $c->blog_id );
            $blogs{ 'blog_' . $c->blog_id } = $blog;
        }
        local $ctx->{ __stash }{ blog } = $blog;
        local $ctx->{ __stash }{ blog_id } = $blog->id;
        local $ctx->{ __stash }{ category } = $c;
        local $ctx->{ __stash }{ class } = $c->class;
        local $ctx->{ __stash }{ vars }{ __class__ } = $c->class;
        my $out = $builder->build( $ctx, $tokens, $cond );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
    }
    return $res;
}

sub _hdlr_og_blogs {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $id = $app->param( 'id' );
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $terms;
    if ( $app->blog ) {
        my $website;
        if ( $app->blog->class eq 'blog' ) {
            require MT::Website;
            $website = MT::Website->load( $app->blog->parent_id );
        } else {
            $website = $app->blog;
        }
        my $blog_ids = get_weblog_ids( $website );
        $terms->{ id } = $blog_ids;
    }
    unless ( $terms->{ id } ) {
        $terms->{ class } = '*';
    }
    my $iter = MT->model( 'blog' )->load_iter( $terms, { limit => 1000 } );
    my $res;
    while ( my $b = $iter->() ) {
        my $order = ObjectGroup::ObjectOrder->load( { objectgroup_id => $id,
                                                      object_id => $b->id,
                                                      object_ds => 'blog' } ) if $id;
        my $website_name;
        if (! $app->blog ) {
            if ( $b->class eq 'blog' ) {
                require MT::Website;
                my $website = MT::Website->load( $b->parent_id );
                $website_name = $website->name if $website;
            }
        }
        next if ( $id && ( defined $order ) );
        local $ctx->{ __stash }{ vars }{ __website_name__ } = $website_name;
        local $ctx->{ __stash }{ blog } = $b;
        local $ctx->{ __stash }{ class } = $b->class;
        my $out = $builder->build( $ctx, $tokens, $cond );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
    }
    return $res;
}

1;
