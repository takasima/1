package Campaign::Campaign;
use strict;
use MT::Author;
use MT::Blog;
use MT::Asset;
use MT::Asset::Image;
use MT::Request;
use MT::Log;
use MT::Tag;
use Campaign::Plugin;
use MT::Util qw( first_n_words dirify );
use MT::I18N qw( const );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_cms path2url current_ts );
# use Campaign::CampaignGroup;
# use Campaign::CampaignOrder;

use base qw( MT::Object MT::Taggable );
__PACKAGE__->install_properties( {
    column_defs => {
        'id'           => 'integer not null auto_increment',
        'blog_id'      => 'integer',
        'title'        => 'string(255)',
        'basename'     => 'string(255)',
        'image_id'     => 'integer',
        'movie_id'     => 'integer',
        'banner_width' => 'integer',
        'banner_height'=> 'integer',
        'text'         => 'text',
        'memo'         => 'string(255)',
        'publishing_on'=> 'datetime',
        'period_on'    => 'datetime',
        'created_on'   => 'datetime',
        'modified_on'  => 'datetime',
        'author_id'    => 'integer',
        'max_displays' => 'integer',
        'uniqdisplays' => 'integer',
        'displays'     => 'integer',
        'max_clicks'   => 'integer',
        'clicks'       => 'integer',
        'uniqclicks'   => 'integer',
        'status'       => 'integer',
        'url'          => 'string(255)',
        'set_period'   => 'integer',
        'class'        => 'string(25)',
        'conversion'   => 'integer',
        'conversionview' => 'integer',
        'max_uniqdisplays' => 'integer',
        'max_uniqclicks'   => 'integer',
        'editor_select' => 'boolean',
        'show_fields'   => 'string meta',
    },
    indexes => {
        'blog_id'      => 1,
        'title'        => 1,
        'basename'     => 1,
        'image_id'     => 1,
        'movie_id'     => 1,
        'memo'         => 1,
        'publishing_on'=> 1,
        'period_on'    => 1,
        'created_on'   => 1,
        'modified_on'  => 1,
        'author_id'    => 1,
        'max_displays' => 1,
        'max_clicks'   => 1,
        'status'       => 1,
        'url'          => 1,
        'set_period'   => 1,
        'tag_count' => {
            columns => [ 'blog_id', 'id' ],
        },
    },
    child_of    => [ 'MT::Blog', 'MT::Website' ],
    datasource  => 'campaign',
    primary_key => 'id',
    class_type  => 'campaign',
    meta => 1,
} );

sub HOLD ()      { 1 }
sub DRAFT ()     { 1 }
sub RELEASE ()   { 2 }
sub PUBLISHED () { 2 }
sub PUBLISHING (){ 2 }
sub FUTURE ()    { 3 }
sub RESERVED ()  { 3 }
sub CLOSE ()     { 4 }
sub FINISED ()   { 4 }
sub ENDED ()     { 4 }

sub status_text {
    my $obj = shift;
    if ( $obj->status == Campaign::Campaign::HOLD() ) {
        return 'Draft';
    }
    if ( $obj->status == Campaign::Campaign::RELEASE() ) {
        return 'Publishing';
    }
    if ( $obj->status == Campaign::Campaign::FUTURE() ) {
        return 'Scheduled';
    }
    if ( $obj->status == Campaign::Campaign::CLOSE() ) {
        return 'Ended';
    }
}

sub class_label {
    my $plugin = MT->component( 'Campaign' );
    return $plugin->translate( 'Campaign' );
}

sub class_label_plural {
    my $plugin = MT->component( 'Campaign' );
    return $plugin->translate( 'Campaigns' );
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

sub image {
    my $obj = shift;
    return undef if (! $obj->image_id );
    my $r = MT::Request->instance;
    my $asset = $r->cache( 'campaign_image:' . $obj->image_id );
    return $asset if defined $asset;
    $asset = MT::Asset::Image->load( $obj->image_id );
    $r->cache( 'campaign_image:' . $obj->image_id, $asset );
    return $asset;
}

sub banner {
    my $obj = shift;
    my $image = $obj->image;
    return undef unless defined $image;
    my $banner_width = $obj->banner_width;
    my $banner_height = $obj->banner_height;
    my $plugin = MT->component( 'Campaign' );
    my $max_banner_size = $plugin->get_config_value( 'max_banner_size', 'blog:'. $obj->blog_id );
    if ( ( $banner_width && $banner_height ) &&
        ( ( $image->image_width != $banner_width ) ||
        ( $image->image_height != $banner_height ) ) ) {
        my %param = ( Width => $banner_width, Height => $banner_height );
        my ( $url, $w, $h ) = $image->thumbnail_file( %param );
        $url = path2url( $url, $obj->blog );
        return ( $url, $banner_width, $banner_height );
    }
    if ( $banner_width && ( $image->image_width != $banner_width ) ) {
        my %param = ( Width => $banner_width );
        my ( $url, $w, $h ) = $image->thumbnail_file( %param );
        $url = path2url( $url, $obj->blog );
        return ( $url, $banner_width, $h );
    }
    if ( $banner_height && ( $image->image_height != $banner_height ) ) {
        my %param = ( Height => $banner_height );
        my ( $url, $w, $h ) = $image->thumbnail_file( %param );
        $url = path2url( $url, $obj->blog );
        return ( $url, $w, $banner_height );
    }
    if ( ( $image->image_width > $max_banner_size ) ||
       ( $image->image_height > $max_banner_size ) ) {
        my %param;
        if ( $image->image_height < $image->image_width ) {
            %param = ( Width => $max_banner_size );
        } else {
            %param = ( Height => $max_banner_size );
        }
        my ( $url, $w, $h ) = $image->thumbnail_file( %param );
        $url = path2url( $url, $obj->blog );
        return ( $url, $w, $h );
    }
    my $url = $image->url;
    my $w = $image->image_width;
    my $h = $image->image_height;
    return ( $url, $w, $h );
}

sub movie {
    my $obj = shift;
    my $r = MT::Request->instance;
    return undef if (! $obj->movie_id );
    my $asset = $r->cache( 'campaign_movie:' . $obj->movie_id );
    return $asset if defined $asset;
    $asset = MT::Asset->load( $obj->movie_id );
    $r->cache( 'campaign_movie:' . $obj->movie_id, $asset );
    return $asset;
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    if ( is_cms( $app ) ) {
        if (! $app->blog ) {
            unless ( $app->mode eq 'save' ||
                     defined $app->param( 'itemset_action_input' ) ||
                     ( $app->param( '_type' ) && $app->param( '_type' ) eq 'website' ) ||
                     ( $app->param( 'website_theme' ) && $app->param( 'website_theme' ) eq 'power_cms_website' )
            ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        } elsif (! Campaign::Plugin::_campaign_permission( $app->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        if (! defined( $obj->basename ) || ( $obj->basename eq '' ) ) {
            my $name = make_unique_basename( $obj );
            $obj->basename( $name );
        }
        unless ( $obj->max_displays() ) {
            $obj->max_displays( 0 );
        }
        unless ( $obj->max_clicks() ) {
            $obj->max_clicks( 0 );
        }
        unless ( $obj->max_uniqdisplays() ) {
            $obj->max_uniqdisplays( 0 );
        }
        unless ( $obj->max_uniqclicks() ) {
            $obj->max_uniqclicks( 0 );
        }
    }
    my $blog = $obj->blog;
    my $is_new;
    if (! $obj->id ) {
        $is_new = 1;
    }
    $obj->modified_on( current_ts( $obj->blog ) );
    $obj->SUPER::save( @_ );
    if ( $is_new ) {
        my @blog_ids;
        if ( $blog->class eq 'blog' ) {
            @blog_ids = ( $blog->id, $blog->parent_id );
        } else {
            push ( @blog_ids, $blog->id );
        }
        require Campaign::CampaignGroup;
        my @groups = Campaign::CampaignGroup->load( { additem => 1, blog_id => \@blog_ids } );
        for my $group ( @groups ) {
            my $addfilter = $group->addfilter;
            if ( $addfilter ) {
                if ( $addfilter eq 'blog' ) {
                    my $addfilter_blog_id = $group->addfilter_blog_id;
                    if ( $addfilter_blog_id ) {
                        if ( $obj->blog_id != $addfilter_blog_id ) {
                            next;
                        }
                    }
                } elsif ( $addfilter eq 'tag' ) {
                    my $addfiltertag = $group->addfiltertag;
                    my @tags = $obj->get_tags;
                    if (! grep( /^$addfiltertag$/, @tags ) ) {
                        next;
                    }
                }
            }
            my $direction;
            if ( $group->addposition ) {
                $direction = 'descend';
            } else {
                $direction = 'ascend';
            }
            require Campaign::CampaignOrder;
            my $last = Campaign::CampaignOrder->load( { group_id => $group->id },
                                                      { sort => 'order',
                                                        direction => $direction,
                                                        limit => 1, } );
            my $pos = 500;
            if ( $last ) {
                $pos = $last->order;
                if ( $group->addposition ) {
                    $pos++;
                } else {
                    $pos--;
                }
            }
            require Campaign::CampaignOrder;
            my $order = Campaign::CampaignOrder->get_by_key( { group_id => $group->id,
                                                               order => $pos,
                                                               campaign_id => $obj->id } );
            $order->save or die $order->errstr;
        }
    }
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        my $id = $obj->id;
        my $title = $obj->title;
        my $app = MT->instance();
        if ( is_cms( $app ) ) {
            if (! $app->validate_magic ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
            if (! Campaign::Plugin::_campaign_permission( $app->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
            require MT::ObjectAsset;
            if ( $obj->image_id ) {
                my @oa = MT::ObjectAsset->load( { blog_id   => $obj->blog_id,
                                                  asset_id  => $obj->image_id,
                                                  object_id => $obj->id,
                                                  object_ds => $obj->datasource, } );
                for my $objectasset ( @oa ) {
                    $objectasset->remove or die $objectasset->errstr;
                }
            }
            if ( $obj->movie_id ) {
                my @oa = MT::ObjectAsset->load( { blog_id   => $obj->blog_id,
                                                  asset_id  => $obj->movie_id,
                                                  object_id => $obj->id,
                                                  object_ds => $obj->datasource, } );
                for my $objectasset ( @oa ) {
                    $objectasset->remove or die $objectasset->errstr;
                }
            }
        }
        $obj->SUPER::remove( @_ );
        if ( is_cms( $app ) ) {
            my $plugin = MT->component( 'Campaign' );
            $app->log( {
                message => $plugin->translate( 'Campaign \'[_1]\' (ID:[_2]) deleted by \'[_3]\'', $title, $id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'campaign',
                level => MT::Log::INFO(),
            } );
            $app->run_callbacks( 'cms_post_delete.campaign', $app, $obj, $obj );
        }
        require Campaign::CampaignOrder;
        my @order = Campaign::CampaignOrder->load( { campaign_id => $obj->id } );
        for my $ord ( @order ) {
            $ord->remove or die $ord->errstr;
        }
        return 1;
    }
    $obj->SUPER::remove( @_ );
}

sub _nextprev {
    my ( $obj, $direction ) = @_;
    my $r = MT::Request->instance;
    my $nextprev = $r->cache( "campaign_$direction:" . $obj->id );
    return $nextprev if defined $nextprev;
    $nextprev = $obj->nextprev(
        direction => $direction,
        terms     => { blog_id => $obj->blog_id },
        by        => 'created_on',
    );
    $r->cache( "campaign_$direction:" . $obj->id, $nextprev );
    return $nextprev;
}

sub make_unique_basename {
    my $obj = shift;
    my $blog = $obj->blog;
    my $title = $obj->title;
    $title = '' if !defined $title;
    $title =~ s/^\s+|\s+$//gs;
    if ( $title eq '' ) {
        if ( my $text = $obj->text ) {
            $title = first_n_words( $text, const( 'LENGTH_ENTRY_TITLE_FROM_TEXT' ) );
        }
        $title = 'Campaign' if $title eq '';
    }
    my $limit = $blog->basename_limit || 30;
    $limit = 15 if $limit < 15; $limit = 250 if $limit > 250;
    my $base = substr( dirify( $title ), 0, $limit );
    $base =~ s/_+$//;
    $base = 'campaign' if $base eq '';
    my $i = 1;
    my $base_copy = $base;
    my $class = ref $obj;
    return MT::Util::_get_basename( $class, $base, $blog );
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        author_id =>{
            class => MT->model('author'),
            optional => 1,
            orphanize => 1
        },
        image_id => {
            class => MT->model( 'asset' ),
            optional => 1
        },
        movie_id => {
            class => MT->model( 'asset' ),
            optional => 1
        },
    };
}

1;
