package CustomGroup::CustomGroup;
use strict;
use base qw( MT::Object );

use CustomGroup::Util qw( is_cms current_ts is_user_can );

my $datasource = 'customgroup';

if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'cg';
}

__PACKAGE__->install_properties( {
    column_defs => {
        'id'          => 'integer not null auto_increment',
        'blog_id'     => 'integer',
        'author_id'   => 'integer',
        'name'        => 'string(255)',
        'additem'     => 'boolean',
        'addposition' => 'boolean',
        'filter'      => 'string(25)',
        'addfilter'   => 'string(25)',
        'filter_container' => 'integer',
        'addfilterclass' => 'string(25)',
        'addfilter_cid' => 'string(25)', # Category ID
        'addfiltertag' => 'string(255)',
        'addfilter_blog_id' => 'integer',
        'template_id' => 'integer',
        'filter_tag' => 'string(25)',
        'class' => 'string(25)',
    },
    indexes => {
        'blog_id'     => 1,
        'author_id'   => 1,
        'name'        => 1,
        'additem'     => 1,
        'created_on'  => 1,
        'modified_on' => 1,
        'created_by'  => 1,
        'filter_container' => 1,
    },
    datasource    => $datasource,
    primary_key   => 'id',
    child_of      => [ 'MT::Blog', 'MT::Website' ],
    class_type    => 'customgroup',
    audit         => 1,
    child_classes => [ 'CustomGroup::GroupOrder' ],
} );

sub child_class { 'customgroup' }

sub class_label {
    my $obj = shift;
    my $class_type = $obj->class_type;
    my $custom_groups = MT->registry( 'custom_groups' );
    if (! $custom_groups->{ $class_type } ) {
        my $plugin = MT->component( 'CustomGroup' );
        return $plugin->translate( 'Object Group' );
    }
    my $component = $custom_groups->{ $class_type }->{ component };
    my $label = $custom_groups->{ $class_type }->{ name };
    my $plugin = MT->component( $component );
    return $plugin->translate( $label );
}

sub class_label_plural {
    my $obj = shift;
    my $class_type = $obj->class_type;
    my $custom_groups = MT->registry( 'custom_groups' );
    if (! $custom_groups->{ $class_type } ) {
        my $plugin = MT->component( 'CustomGroup' );
        return $plugin->translate( 'Object Groups' );
    }
    my $component = $custom_groups->{ $class_type }->{ component };
    my $label = $custom_groups->{ $class_type }->{ name_plural };
    my $plugin = MT->component( $component );
    return $plugin->translate( $label );
}

MT::Blog->add_callback(
    'pre_remove', 0,
    MT->component( 'core' ),
    sub {
        my ( $cb, $obj, $original ) = @_;
        my @objects = __PACKAGE__->load( { blog_id => $obj->id, class => '*' } );
        for my $obj ( @objects ) {
            $obj->remove;
        }
        return 1;
    }
);

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'CustomGroup' );
    my $is_new;
    if ( ( is_cms( $app ) ) && ( $app->mode eq 'save' )
        && ( $app->param( '_type' ) eq $obj->class ) ) {
        if (! $obj->can_edit ) {
            $app->return_to_dashboard( permission => 1 );
        }
        my $child_class = $obj->child_class;
        my $child_class_label;
        if ( ( ref $child_class ) eq 'ARRAY' ) {
            $child_class_label = $obj->child_class_label;
        } else {
            $child_class_label = MT->model( $obj->child_class )->class_label;
        }
        require CustomGroup::GroupOrder;
        ## TODO::Check permission
        ## TODO::To pre_save.foo
        my $blog_id = 0;
        if ( $app->blog ) {
            $blog_id = $app->blog->id;
        }
        my $g = MT->model( $obj->class )->load( { name => $obj->name, blog_id => $blog_id } );
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
            @order_old = CustomGroup::GroupOrder->load( { group_id => $obj->id } );
            my $author = MT->model( 'author' )->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
        } else {
            $obj->author_id( $app->user->id );
            $obj->SUPER::save( @_ );
            $is_new = 1;
            $app->log( {
                message => $plugin->translate( '[_1] Group \'[_2]\' (ID:[_3]) created by \'[_4]\'', $child_class_label, $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
        }
        my $sort = $app->param( 'sort' );
        my @sort_id = split( /,/, $sort );
        my $i = 500; my @add_items;
        for my $object_id ( @sort_id ) {
            my $item = MT->model( $obj->child_object_ds )->load( $object_id );
            if ( $item ) {
                my $order = CustomGroup::GroupOrder->get_by_key( { group_id => $obj->id,
                                                                object_id => $object_id } );
                $order->object_class( $item->has_column( 'class' ) ? $item->class : $item->datasource );
                $order->blog_id( $obj->blog_id );
                $order->order( $i );
                $order->save or die $order->errstr;
                push ( @add_items, $order->id );
                $i++;
            }
        }
        for my $old ( @order_old ) {
            my $order_id = $old->id;
            if (! grep( /^$order_id$/, @add_items ) ) {
               $old->remove or die $old->errstr;
            }
        }
        if (! $is_new ) {
            $app->log( {
                message => $plugin->translate( '[_1] Group \'[_2]\' (ID:[_3]) edited by \'[_4]\'', $child_class_label, $obj->name, $obj->id, $app->user->name ),
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
            if (! $obj->can_edit ) {
                $app->return_to_dashboard( permission => 1 );
            }
        }
        $obj->SUPER::remove( @_ );
        require CustomGroup::GroupOrder;
        my @order = CustomGroup::GroupOrder->load( { group_id => $id } );
        for my $item ( @order ) {
            $item->remove or die $item->errstr;
        }
        if ( is_cms( $app ) ) {
            my $plugin = MT->component( 'CustomGroup' );
            my $child_class = $obj->child_class;
            my $child_class_label;
            if ( ( ref $child_class ) eq 'ARRAY' ) {
                $child_class_label = $obj->child_class_label;
            } else {
                $child_class_label = MT->model( $obj->child_class )->class_label;
            }
            $app->log( {
                message => $plugin->translate( '[_1] Group \'[_2]\' (ID:[_3]) deleted by \'[_4]\'', $child_class_label, $name, $id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
        }
        return 1;
    }
    $obj->SUPER::remove( @_ );
    return 1;
}

sub can_edit {
    my $obj = shift;
    my $user = MT->instance->user;
    return 1 if $user->is_superuser;
    if (! $obj->blog_id ) {
        return 0;
    }
    my $blog = $obj->blog;
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'edit_config' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_' . $obj->class ) ) {
        return 1;
    }
    return 0;
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    if ( $obj->has_column( 'blog_id' ) ) {
        return 1 if $user->permissions( $obj->blog_id )->can_administer_blog;
        return 1 if $user->permissions( $obj->blog_id )->can_administer_website;
    }
    return 0;
}

sub children_count {
    my $obj = shift;
    require CustomGroup::GroupOrder;
    return CustomGroup::GroupOrder->count( { group_id => $obj->id } );
}

sub author {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $key = 'cache_author:' . $obj->author_id;
    my $author = $r->cache($key);
    return $author if defined $author;
    require MT::Author;
    $author = MT::Author->load( $obj->author_id ) if $obj->author_id;
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'CustomGroup' );
        $author->name( $plugin->translate( '(Unknown)' ) );
        $author->nickname( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( $key, $author );
    return $author;
}

sub blog {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $key = 'cache_blog:' . $obj->blog_id;
    my $blog = $r->cache( $key );
    return $blog if defined $blog;
    require MT::Blog;
    if (! $obj->blog_id ) {
        $blog = MT::Blog->new;
        $blog->name( MT->translate( 'System' ) );
        return $blog;
    }
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( $key, $blog );
    return $blog;
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        addfilter_blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
#        template_id => MT->model( 'template' ),
#        addfilter_cid => [ MT->model( 'category' ), MT->model( 'folder' ) ],
    };
}

# following for datasource,
# original is from MT::Object::to_xml written in MT::BackupRestore.
sub to_xml {
    my $obj = shift;
    my ( $namespace, $metacolumns ) = @_;

    my $coldefs  = $obj->column_defs;
    my $colnames = $obj->column_names;
    my $xml;

    my $elem = $obj->datasource;

    # PATCH
    $elem = 'customgroup';
    # /PATCH

    unless ( UNIVERSAL::isa( $obj, 'MT::Log' ) ) {
        if ( $obj->properties
            && ( my $ccol = $obj->properties->{class_column} ) )
        {
            if ( my $class = $obj->$ccol ) {

                # use class_type value instead if
                # the value resolves to a Perl package
                $elem = $class
                    if defined( MT->model($class) );
            }
        }
    }

    $xml = '<' . $elem;
    $xml .= " xmlns='$namespace'" if defined($namespace) && $namespace;

    my ( @elements, @blobs, @meta );
    for my $name (@$colnames) {
        if ($obj->column($name)
            || ( defined( $obj->column($name) )
                && ( '0' eq $obj->column($name) ) )
            )
        {
            if ( ( $obj->properties->{meta_column} || '' ) eq $name ) {
                push @meta, $name;
                next;
            }
            elsif ( $obj->_is_element( $coldefs->{$name} ) ) {
                push @elements, $name;
                next;
            }
            elsif ( 'blob' eq $coldefs->{$name}->{type} ) {
                push @blobs, $name;
                next;
            }
            $xml .= " $name='"
                . MT::Util::encode_xml( $obj->column($name), 1 ) . "'";
        }
    }
    my ( @meta_elements, @meta_blobs );
    if ( defined($metacolumns) && @$metacolumns ) {
        foreach my $metacolumn (@$metacolumns) {
            my $name = $metacolumn->{name};
            if ( $obj->$name
                || ( defined( $obj->$name ) && ( '0' eq $obj->$name ) ) )
            {
                if ( 'vclob' eq $metacolumn->{type} ) {
                    push @meta_elements, $name;
                }
                elsif ( 'vblob' eq $metacolumn->{type} ) {
                    push @meta_blobs, $name;
                }
                else {
                    $xml .= " $name='"
                        . MT::Util::encode_xml( $obj->$name, 1 ) . "'";
                }
            }
        }
    }
    $xml .= '>';
    $xml .= "<$_>" . MT::Util::encode_xml( $obj->column($_), 1 ) . "</$_>"
        foreach @elements;
    require MIME::Base64;
    foreach my $blob_col (@blobs) {
        my $val = $obj->column($blob_col);
        if ( substr( $val, 0, 4 ) eq 'SERG' ) {
            $xml
                .= "<$blob_col>"
                . MIME::Base64::encode_base64( $val, '' )
                . "</$blob_col>";
        }
        else {
            $xml .= "<$blob_col>"
                . MIME::Base64::encode_base64(
                Encode::encode( MT->config->PublishCharset, $val ), '' )
                . "</$blob_col>";
        }
    }
    foreach my $meta_col (@meta) {
        my $hashref = $obj->$meta_col;
        $xml .= "<$meta_col>"
            . MIME::Base64::encode_base64(
            MT::Serialize->serialize( \$hashref ), '' )
            . "</$meta_col>";
    }
    $xml .= "<$_>" . MT::Util::encode_xml( $obj->$_, 1 ) . "</$_>"
        foreach @meta_elements;
    foreach my $vblob_col (@meta_blobs) {
        my $vblob = $obj->$vblob_col;
        $xml .= "<$vblob_col>"
            . MIME::Base64::encode_base64(
            MT::Serialize->serialize( \$vblob ), '' )
            . "</$vblob_col>";
    }
    $xml .= '</' . $elem . '>';
    $xml;
}

1;
