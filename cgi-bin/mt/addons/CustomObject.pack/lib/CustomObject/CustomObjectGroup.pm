package CustomObject::CustomObjectGroup;
use strict;
use base qw( MT::Object );

use CustomObject::Util qw( is_cms current_ts );

my $datasource;
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'cog';
} else {
    $datasource = 'customobjectgroup';
}

__PACKAGE__->install_properties( {
    column_defs => {
        'id'          => 'integer not null auto_increment',
        'blog_id'     => 'integer',
        'author_id'   => 'integer',
        'name'        => 'string(255)',
        'additem'     => 'boolean',
        'addposition' => 'boolean',
        'created_on'  => 'datetime',
        'modified_on' => 'datetime',
        'template_id' => 'integer',
        'addfilter'   => 'string(25)',
        'addfiltertag' => 'string(255)',
        'addfilter_blog_id' => 'integer',
        'class'       => 'string(25)',
        'filter_tag'  => 'string(25)',
    },
    indexes => {
        'blog_id'     => 1,
        'author_id'   => 1,
        'name'        => 1,
        'additem'     => 1,
        'created_on'  => 1,
        'modified_on' => 1,
        'addfilter'   => 1,
    },
    datasource    => $datasource,
    primary_key   => 'id',
    child_of      => [ 'MT::Blog', 'MT::Website' ],
    class_type    => 'customobjectgroup',
    child_classes => [ 'CustomObject::CustomObjectOrder' ],
} );

sub child_class {
    return 'customobject';
}

sub class_label {
    my $app = MT->instance;
    if ( is_cms( $app ) ) {
        my $model = $app->param( 'class' );
        if ( $model && $model ne 'customobject' ) {
            $model =~ s/group$//;
            my $custom_objects = MT->registry( 'custom_objects' );
            my @objects = keys( %$custom_objects );
            if ( grep( /^$model$/, @objects ) ) {
                if ( my $class = MT->model( $model ) ) {
                    return $class->group_label;
                }
            }
        }
    }
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject Group' );
}

sub class_label_plural {
    my $app = MT->instance;
    if ( is_cms( $app ) ) {
        my $model = $app->param( 'class' );
        if ( $model && $model ne 'customobject' ) {
            $model =~ s/group$//;
            my $custom_objects = MT->registry( 'custom_objects' );
            my @objects = keys( %$custom_objects );
            if ( grep( /^$model$/, @objects ) ) {
                if ( my $class = MT->model( $model ) ) {
                    return $class->group_label_plural;
                }
            }
        }
    }
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject Groups' );
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'CustomObject' );
    require MT::Log;
    my $is_new;
    if (! $obj->class ) {
        $obj->class( 'customobject' );
    }
    if ( ( is_cms( $app ) ) && ( $app->mode eq 'save' ) &&
        ( $app->param( '_type' ) ) && ( $app->param( '_type' ) eq 'customobjectgroup' ) ) {
        require CustomObject::CustomObject;
        if (! $app->validate_magic ) {
            $app->return_to_dashboard();
            return 0;
        } else {
            if (! CustomObject::Plugin::_customobject_permission( $app->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        my $g = CustomObject::CustomObjectGroup->load( { name => $obj->name, blog_id => $app->blog->id, class => $obj->class } );
        if ( $g ) {
            if (! $obj->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            } else {
                if ( $obj->id != $g->id ) {
                    die $plugin->translate( 'Another group already exists by that name.' );
                }
            }
        }
        my @order_old;
        my $current_ts = current_ts( $app->blog );
        $obj->modified_on( $current_ts );
        if ( $obj->id ) {
            @order_old = CustomObject::CustomObjectOrder->load( { group_id => $obj->id } );
            require MT::Author;
            my $author = MT::Author->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
            if (! $obj->created_on ) {
                $obj->created_on( $current_ts );
            }
        } else {
            $obj->author_id( $app->user->id );
            $obj->created_on( $current_ts );
            $obj->SUPER::save( @_ );
            $is_new = 1;
            $app->log( {
                message => $plugin->translate( '[_1] Group \'[_2]\' (ID:[_3]) created by \'[_4]\'', $obj->label, $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->child_class,
                level => MT::Log::INFO(),
            } );
        }
        my $sort = $app->param( 'sort' );
        my @sort_id = split( /,/, $sort );
        my $i = 500; my @add_items;
        for my $object_id ( @sort_id ) {
            my $customobject = CustomObject::CustomObject->load( $object_id );
            if ( $customobject ) {
                my $order = CustomObject::CustomObjectOrder->get_by_key( { group_id => $obj->id,
                                                                   customobject_id => $object_id } );
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
                message => $plugin->translate( '[_1] Group \'[_2]\' (ID:[_3]) edited by \'[_4]\'', $obj->label, $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->child_class,
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
        require CustomObject::CustomObject;
        my $id = $obj->id;
        my $name = $obj->name;
        my $app = MT->instance();
        if ( is_cms( $app ) ) {
            if (! $app->validate_magic ) {
                $app->return_to_dashboard();
                return 0;
            } else {
                if (! CustomObject::Plugin::_customobject_permission( $app->blog ) ) {
                    $app->return_to_dashboard( permission => 1 );
                    return 0;
                }
            }
        }
        $obj->SUPER::remove( @_ );
        my @order = CustomObject::CustomObjectOrder->load( { group_id => $id } );
        for my $item ( @order ) {
            $item->remove or die $item->errstr;
        }
        if ( is_cms( $app ) ) {
            my $plugin = MT->component( 'CustomObject' );
            require MT::Log;
            $app->log( {
                message => $plugin->translate( '[_1] Group \'[_2]\' (ID:[_3]) deleted by \'[_4]\'', $obj->label, $name, $id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->child_class,
                level => MT::Log::INFO(),
            } );
        }
        return 1;
    }
    $obj->SUPER::remove( @_ );
}

sub author {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'cache_author:' . $obj->author_id );
    return $author if defined $author;
    require MT::Author;
    $author = MT::Author->load( $obj->author_id ) if $obj->author_id;
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'CustomObject' );
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
    my $blog = $r->cache( 'cache_blog:' . $obj->blog_id );
    return $blog if defined $blog;
    require MT::Blog;
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( 'cache_blog:' . $obj->blog_id, $blog );
    return $blog;
}

sub label {
    my $obj = shift;
    my ( $label_en, $label_ja, $label_plural ) = $obj->labels;
    if ( MT->instance->user->preferred_language eq 'ja' ) {
        return $label_ja;
    }
    return $label_en;
}

sub labels {
    my $obj = shift;
    require CustomObject::Plugin;
    my $plugin = '';
    if ( $obj->class ne 'customobject' ) {
        $plugin = $obj->class;
    }
    return CustomObject::Plugin::__get_settings( MT->instance, $obj->blog, $plugin );
}

sub children_count {
    my $obj = shift;
    require CustomObject::CustomObjectOrder;
    return CustomObject::CustomObjectOrder->count( { group_id => $obj->id } );
}

sub children {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $customobjects = $r->cache( 'cache_customobject_children:' . $obj->id );
    if (! $customobjects ) {
        my %params;
        require CustomObject::CustomObject;
        $params { 'join' } = [ 'CustomObject::CustomObjectOrder', 'customobject_id',
                               { group_id => $obj->id, },
                               { sort   => 'order',
                                 direction => 'ascend',
                               } ];
        my @objects = MT->model( $obj->class )->load( undef, \%params );
        $customobjects = \@objects;
        $r->cache( 'cache_customobject_children:' . $obj->id, $customobjects );
    }
    if ( wantarray ) {
        return @$customobjects;
    } else {
        return $customobjects;
    }
}

sub published_children {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $customobjects = $r->cache( 'cache_customobject_published_children:' . $obj->id );
    if (! $customobjects ) {
        my %params;
        require CustomObject::CustomObjectOrder;
        $params { 'join' } = [ 'CustomObject::CustomObjectOrder', 'customobject_id',
                               { group_id => $obj->id }, ];
        $params{ no_class } = 1;
#        $customobjects = MT->model( $obj->child_class )->count( undef, \%params );
        $customobjects = MT->model( $obj->child_class )->count( { status => CustomObject::CustomObject::RELEASE() }, \%params );
        $r->cache( 'cache_customobject_published_children:' . $obj->id, $customobjects );
    }
    return $customobjects;
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
#         author_id => MT->model( 'author' ),
    };
}

sub default_module_mtml {
    my $template = <<MTML;
<MTCustomObjects group_id="\$group_id">
<MTCustomObjectsHeader><ul></MTCustomObjectsHeader>
    <li><MTCustomObjectName escape="html"></li>
<MTCustomObjectsFooter></ul></MTCustomObjectsFooter>
</MTCustomObjects>
MTML
    return $template;
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
    $elem = 'customobjectgroup';
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

sub child_key { 'group_id'; }

1;
