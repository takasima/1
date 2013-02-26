package Campaign::CampaignGroup;
use strict;
use MT::Author;
use MT::Blog;
use MT::Request;
use MT::Log;
use Campaign::Plugin;
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_cms current_ts flush_blog_cmscache );

my $datasource = 'campaigngroup';
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'cpg';
}

use base qw( MT::Object );
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
        'addfilter'   => 'string(25)',
        'addfiltertag' => 'string(255)',
        'addfilter_blog_id' => 'integer',
        'template_id' => 'integer',
        'filter' => 'string(25)',
        'filter_tag' => 'string(25)',
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
    child_classes => [ 'Campaign::CampaignOrder' ],
} );

sub children_count {
    my $obj = shift;
    require Campaign::CampaignOrder;
    return Campaign::CampaignOrder->count( { group_id => $obj->id } );
}

sub class_label {
    my $plugin = MT->component( 'Campaign' );
    return $plugin->translate( 'Campaign Group' );
}

sub class_label_plural {
    my $plugin = MT->component( 'Campaign' );
    return $plugin->translate( 'Campaign Groups' );
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'Campaign' );
    my $is_new;
    if ( ( is_cms( $app ) ) && ( $app->mode eq 'save' )
        && ( $app->param( '_type' ) eq 'campaigngroup' ) ) {
        if (! $app->blog ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        if (! Campaign::Plugin::_group_permission( $app->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        my $g = Campaign::CampaignGroup->load( { name => $obj->name, blog_id => $app->blog->id } );
        if ( $g ) {
            if (! $obj->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            }
            if ( $obj->id != $g->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            }
        }
        my @order_old;
        my $current_ts = current_ts( $app->blog );
        $obj->modified_on( $current_ts );
        if ( $obj->id ) {
            require Campaign::CampaignOrder;
            @order_old = Campaign::CampaignOrder->load( { group_id => $obj->id } );
            my $author = MT::Author->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->blog->id );
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
                message => $plugin->translate( 'Campaign Group \'[_1]\' (ID:[_2]) created by \'[_3]\'', $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'campaign',
                level => MT::Log::INFO(),
            } );
        }
        my $sort = $app->param( 'sort' );
        my @sort_id = split( /,/, $sort );
        my $i = 500; my @add_items;
        for my $object_id ( @sort_id ) {
            require Campaign::Campaign;
            my $campaign = Campaign::Campaign->load( $object_id );
            if ( $campaign ) {
                require Campaign::CampaignOrder;
                my $order = Campaign::CampaignOrder->get_by_key( { group_id => $obj->id,
                                                                   campaign_id => $object_id } );
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
        $app->log( {
            message => $plugin->translate( 'Campaign Group \'[_1]\' (ID:[_2]) edited by \'[_3]\'', $obj->name, $obj->id, $app->user->name ),
            blog_id => $obj->blog_id,
            author_id => $app->user->id,
            class => 'campaign',
            level => MT::Log::INFO(),
        } );
    }
    if (! $is_new ) {
        $obj->SUPER::save( @_ );
    }
    # flush_blog_cmscache( $obj->blog );
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        my $id = $obj->id;
        my $name = $obj->name;
        my $app = MT->instance();
        if ( is_cms( $app ) ) {
            if (! $app->blog ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
            if (! Campaign::Plugin::_group_permission( $app->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        $obj->SUPER::remove( @_ );
        require Campaign::CampaignOrder;
        my @order = Campaign::CampaignOrder->load( { group_id => $id } );
        for my $item ( @order ) {
            $item->remove or die $item->errstr;
        }
        if ( is_cms( $app ) ) {
            my $plugin = MT->component( 'Campaign' );
            $app->log( {
                message => $plugin->translate( 'Campaign Group \'[_1]\' (ID:[_2]) deleted by \'[_3]\'', $name, $id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'campaign',
                level => MT::Log::INFO(),
            } );
        }
        return 1;
    }
    # flush_blog_cmscache( $obj->blog );
    $obj->SUPER::remove( @_ );
}

sub author {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'cache_author:' . $obj->author_id );
    return $author if defined $author;
    $author = MT::Author->load( $obj->author_id ) if $obj->author_id;
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'Campaign' );
        $author->name( $plugin->translate( '(Unknown)' ) );
        $author->nickname( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( 'cache_author:' . $obj->author_id, $author );
    return $author;
}

sub blog {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $blog = $r->cache( 'cache_blog:' . $obj->blog_id );
    return $blog if defined $blog;
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( 'cache_blog:' . $obj->blog_id, $blog );
    return $blog;
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        template_id => {
            class => MT->model( 'template' ),
            optional => 1
        },
    };
}

sub to_xml {
    my $obj = shift;
    my ( $namespace, $metacolumns ) = @_;

    my $coldefs  = $obj->column_defs;
    my $colnames = $obj->column_names;
    my $xml;

    my $elem = $obj->datasource;

    # PATCH
    $elem = 'campaigngroup';
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
