package ObjectGroup::ObjectGroup;
use strict;
use base qw( MT::Object );
use CustomGroup::Util qw( is_cms current_ts is_user_can );

__PACKAGE__->install_properties( {
    column_defs => {
        'id'   => 'integer not null auto_increment',
        'blog_id' => 'integer',
        'author_id' => 'integer',
        'name' => 'string(255)',
        'template_id' => 'integer',
        'class' => 'string(25)',
    },
    indexes => {
        'blog_id' => 1,
        'author_id' => 1,
        'name' => 1,
        'created_on'  => 1,
        'modified_on' => 1,
        'created_by'  => 1,
    },
    datasource    => 'objectgroup',
    class_type    => 'objectgroup',
    primary_key   => 'id',
    audit         => 1,
    child_classes => [ 'ObjectGroup::ObjectOrder' ],
    child_of      => [ 'MT::Blog', 'MT::Website' ],
} );

sub class_label {
    my $plugin = MT->component( 'CustomGroup' );
    return $plugin->translate( 'Object Group' );
}

sub class_label_plural {
    my $plugin = MT->component( 'CustomGroup' );
    return $plugin->translate( 'Object Groups' );
}

sub children_count {
    my $obj = shift;
    require ObjectGroup::ObjectOrder;
    my $count = ObjectGroup::ObjectOrder->count( { objectgroup_id => $obj->id } );
    return $count || 0;
}

sub author {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'cache_author:' . $obj->author_id );
    return $author if defined $author;
    require MT::Author;
    $author = MT::Author->load( $obj->author_id ) if $obj->author_id;
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'CustomGroup' );
        $author->name( $plugin->translate( '(Unknown)' ) );
        $author->nickname( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( 'cache_author:' . $obj->author_id, $author );
    return $author;
}

sub blog {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'cache_blog:' . $obj->blog_id;
    my $blog = $r->cache( $k );
    return $blog if defined $blog;
    require MT::Blog;
    if (! $obj->blog_id ) {
        $blog = MT::Blog->new;
        $blog->name( MT->translate( 'System' ) );
        return $blog;
    }
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( $k, $blog );
    return $blog;
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'CustomGroup' );
    my $is_new;
    if ( ( is_cms( $app ) ) && ( $app->mode eq 'save' )
        && ( $app->param( '_type' ) eq 'objectgroup' ) ) {
        if (! _group_permission( $app->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        require ObjectGroup::ObjectOrder;
        my $blog_id = 0;
        if ( $app->blog ) {
            $blog_id = $app->blog->id;
        } else {
            $obj->blog_id( 0 );
        }
        my $g = ObjectGroup::ObjectGroup->load( { name => $obj->name, blog_id => $blog_id } );
        if ( $g ) {
            if (! $obj->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            }
            if ( $obj->id != $g->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            }
        }
        my @order_old;
        if ( $obj->id ) {
            @order_old = ObjectGroup::ObjectOrder->load( { objectgroup_id => $obj->id } );
            my $author = MT->model( 'author' )->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
        } else {
            $obj->author_id( $app->user->id );
            $obj->SUPER::save( @_ );
            $is_new = 1;
            $app->log( {
                message => $plugin->translate( "[_1] Group '[_2]' (ID:[_3]) created by '[_4]'",
                    $plugin->translate( 'Object' ), $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
        }
        my $id = $obj->id;
        my $sort = $app->param( 'sort' );
        my @sort_id = split( /,/, $sort );
        my $i = 500; my @add_items;
        my %ds_tbl = qw/entry 1 category 1 blog 1/;
        my @objs = split( /,/, $sort );
        for my $obj ( @objs ) {
            my @datas = split( /_/, $obj );
            my $object_ds = $datas[0];
            my $object_id = $datas[1];
            next unless $ds_tbl{ $object_ds };
            my $o = $app->model( $object_ds )->load( $object_id )
                or next;
            my $class = $o->class;
            my $order = ObjectGroup::ObjectOrder->get_by_key( {
                number => $i,
                class  => $class,
                object_ds => $object_ds,
                object_id => $object_id,
                objectgroup_id => $id,
            } );
            $order->blog_id( $blog_id );
            $order->save or die $order->errstr;
            push ( @add_items, $order->id );
            $i++;
        }
        for my $old ( @order_old ) {
            my $order_id = $old->id;
            if (! grep( /^$order_id$/, @add_items ) ) {
               $old->remove or die $old->errstr;
            }
        }
        if (! $is_new ) {
            $app->log( {
                message => $plugin->translate( "[_1] Group '[_2]' (ID:[_3]) edited by '[_4]'",
                    $plugin->translate( 'Object' ), $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
        }
    }
    if (! $is_new ) {
        $obj->SUPER::save( @_ );
    }
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        require MT::Log;
        my $id = $obj->id;
        my $name = $obj->name;
        my $app = MT->instance();
        if ( is_cms( $app ) ) {
            if (! _group_permission( $app->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        $obj->SUPER::remove( @_ );
        require ObjectGroup::ObjectOrder;
        my @order = ObjectGroup::ObjectOrder->load( { objectgroup_id => $id } );
        for my $item ( @order ) {
            $item->remove or die $item->errstr;
        }
        if ( is_cms( $app ) ) {
            my $plugin = MT->component( 'CustomGroup' );
            $app->log( {
                message => $plugin->translate( "[_1] Group '[_2]' (ID:[_3]) deleted by '[_4]'",
                    $plugin->translate( 'Object' ), $name, $id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
        }
        return 1;
    }
    $obj->SUPER::remove( @_ );
}

sub _group_permission {
    my ( $blog ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog ||= $app->blog;
    return 1 if $user->is_superuser;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_objectgroup'%" } );
        require MT::Permission;
        if ( my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] ) ) {
            return 1;
        }
        return 0;
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_objectgroup' ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
#        template_id => MT->model( 'template' ),
    };
}

1;
