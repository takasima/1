package Link::Link;
use strict;
use MT::Blog;
use MT::Author;
use MT::Request;
use MT::Util qw( trim );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_cms current_ts valid_ts get_content );
use Link::LinkGroup;
use Link::LinkOrder;
use MT::Log;
use MT::Tag;
use MT::ConfigMgr;

use base qw( MT::Object MT::Taggable );
__PACKAGE__->install_properties( {
    column_defs => {
        'id'          => 'integer not null auto_increment',
        'blog_id'     => 'integer',
        'author_id'   => 'integer',
        'name'        => 'string(255)',
        'url'         => 'string(255)',
        'title'       => 'string(255)',
        'description' => 'string(255)',
        'target'      => 'string(255)',
        'rel' => 'string(255)',
        'image_address' => 'string(255)',
        'rss_address' => 'string(255)',
        'digest' => 'string(255)',
        'notes' => 'text',
        'rating' => 'integer',
        'editor_select' => 'boolean',
        'broken_link' => 'boolean',
        'broken_rss'  => 'boolean',
        'broken_image'=> 'boolean',
        'authored_on' => 'datetime',
        'created_on'  => 'datetime',
        'modified_on' => 'datetime',
        'urlupdated_on' => 'datetime',
        'rssupdated_on' => 'datetime',
        'status' => 'integer',
        'class'  => 'string(25)',
    },
    indexes => {
        'blog_id'     => 1,
        'author_id'   => 1,
        'name'        => 1,
        'created_on'  => 1,
        'modified_on' => 1,
        'broken_link' => 0,
        'broken_rss'  => 0,
        'broken_image'=> 0,
        'url' => 1,
        'status' => 1,
        'rating' => 1,
        'authored_on' => 1,
        'urlupdated_on' => 1,
        'rssupdated_on' => 1,
        'tag_count' => {
            columns => [ 'blog_id', 'id' ],
        },
    },
    child_of    => [ 'MT::Blog', 'MT::Website' ],
    datasource  => 'link',
    primary_key => 'id',
    class_type  => 'link',
    defaults    => {
        'broken_link' => 0,
        'broken_rss' => 0,
        'broken_image' => 0,
    },
} );

sub HOLD ()       { 1 }
sub DRAFT ()      { 1 }
sub RELEASE ()    { 2 }
sub PUBLISHED ()  { 2 }
sub PUBLISHING () { 2 }

sub status_text {
    my $obj = shift;
    if ( $obj->status == HOLD() ) {
        return 'Draft';
    }
    if ( $obj->status == RELEASE() ) {
        return 'Publishing';
    }
}

sub class_label {
    my $plugin = MT->component( 'Link' );
    return $plugin->translate( 'Link' );
}

sub class_label_plural {
    my $plugin = MT->component( 'Link' );
    return $plugin->translate( 'Links' );
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'Link' );
    my $original;
    my $is_new;

    if ( is_cms( $app ) ) {
        if (! $obj->blog ) {
            $app->return_to_dashboard();
            return 0;
        }
        if (! Link::Plugin::_link_permission( $obj->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        my $check_outlink = $plugin->get_config_value( 'check_outlink', 'blog:'. $obj->blog->id );
        if ( $app->mode ne 'save' ) {
            $check_outlink = 0;
        }
        $check_outlink = 0 unless MT::ConfigMgr->instance->DoSavedLinkCheck;
        my $ua;
        require LWP::UserAgent;
        require HTTP::Date;
        require Digest::MD5;
        if ( $check_outlink ) {
            my $remote_ip = $app->remote_ip;
            my $agent = "Mozilla/5.0 (Movable Type Link plugin X_FORWARDED_FOR:$remote_ip)";
            $ua = LWP::UserAgent->new( agent => $agent );
        }
        my $ts = current_ts( $obj->blog );
        my $columns = $obj->column_names;
        if ( $app->mode eq 'save' ) {
            for my $column ( @$columns ) {
                if ( $column =~ /_on$/ ) {
                    my $date = trim( $app->param( $column . '_date' ) );
                    my $time = trim( $app->param( $column . '_time' ) );
                    if ( $date && $time ) {
                        $date =~ s/-+//g;
                        $time =~ s/:+//g;
                        my $ts_on = $date . $time;
                        if ( valid_ts( $ts_on ) ) {
                            $obj->$column( $ts_on );
                        }
                    }
                }
            }
        }
        if (! $obj->created_on ) {
            $obj->created_on( $ts );
        }
        $obj->modified_on( $ts );
        if ( $obj->id ) {
            my $author = MT::Author->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
        } else {
            $obj->author_id( $app->user->id );
        }
        if (! $obj->status ) {
            $obj->status( HOLD() );
        }
        if ( $check_outlink ) {
            if ( $obj->url ) {
                my $response = $ua->head( $obj->url );
                if (! $response->is_success ) {
                    $obj->broken_link( 1 );
                    $obj->urlupdated_on( undef );
                } else {
                    $obj->broken_link( 0 );
                    my $content = get_content( $obj->url );
                    if ( $content ) {
                        $content = Digest::MD5::md5_hex( $content );
                        if ( (! $obj->digest ) || ( $obj->digest ne $content ) ) {
                            my ( $year, $mon, $day, $hour, $min, $sec, $tz ) = HTTP::Date::parse_date( $response->header( "Last-Modified" ) );
                            my $modified = sprintf( "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec );
                            if (! valid_ts( $modified ) ) {
                                $modified = current_ts( $obj->blog );
                            }
                            $obj->urlupdated_on( $modified );
                            $obj->digest( $content );
                        }
                    }
                }
            } else {
                $obj->broken_link( 1 );
                $obj->urlupdated_on( undef );
            }
            if ( $obj->rss_address ) {
                my $response = $ua->head( $obj->rss_address );
                if (! $response->is_success ) {
                    $obj->broken_rss( 1 );
                    $obj->rssupdated_on( undef );
                } else {
                    $obj->broken_rss( 0 );
                    my $content = get_content( $obj->rss_address );
                    my $modified;
                    if ( ( $content ) && ( $content =~ m!^.*?<.*?date.*?>(.*?)</.*?date.*?>!si ) ) {
                        $modified = $1;
                    } else {
                        $modified = $response->header( "Last-Modified" );
                    }
                    my ( $year, $mon, $day, $hour, $min, $sec, $tz ) = HTTP::Date::parse_date( $modified );
                    $modified = sprintf( "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec );
                    if ( ( ! $obj->rssupdated_on ) || ( $obj->rssupdated_on ne $modified ) ) {
                        $obj->rssupdated_on( $modified );
                    }
                }
            } else {
                $obj->broken_rss( 0 );
            }
            if ( $obj->image_address ) {
                my $response = $ua->head( $obj->image_address );
                if (! $response->is_success ) {
                    $obj->broken_image( 1 );
                } else {
                    $obj->broken_image( 0 );
                }
            } else {
                $obj->broken_image( 0 );
            }
        }
        if ( $obj->id ) {
            $original = MT::Request->instance->cache( 'link_original' . $obj->id );
            if (! $original ) {
                $original = $obj->clone_all();
            }
        }
        if ( $app->mode eq 'save' ) {
            if ( my $tags  = $app->param( 'tags' ) ) {
                my @t = split( /,/, $tags );
                $obj->set_tags( @t );
            } else {
                $obj->remove_tags();
            }
        }
        # if ( $app->mode eq 'save' ) {
        #     $app->run_callbacks( 'cms_pre_save.link', $app, $obj, $original ) or return 0;
        # }
    }
    my $blog = $obj->blog;
    if (! $obj->id ) {
        $is_new = 1;
    }
    $obj->class( 'link' );
    $obj->SUPER::save( @_ );
    if ( $is_new ) {
        if ( $app->mode eq 'save' ) {
            $app->log( {
                message => $plugin->translate( 'Link \'[_1]\' (ID:[_2]) created by \'[_3]\'', $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'link',
                level => MT::Log::INFO(),
            } );
        }
        my @blog_ids;
        if ( $blog->class eq 'blog' ) {
            @blog_ids = ( $blog->id, $blog->parent_id );
        } else {
            push ( @blog_ids, $blog->id );
        }
        my @groups = Link::LinkGroup->load( { additem => 1, blog_id => \@blog_ids } );
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
            my $last = Link::LinkOrder->load( { group_id => $group->id },
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
            my $order = Link::LinkOrder->get_by_key( { group_id => $group->id,
                                                       order => $pos,
                                                       link_id => $obj->id } );
            $order->save or die $order->errstr;
        }
    }
    if ( is_cms( $app ) ) {
        if ( $app->mode eq 'save' ) {
            if (! $is_new ) {
                $app->log( {
                    message => $plugin->translate( 'Link \'[_1]\' (ID:[_2]) edited by \'[_3]\'', $obj->name, $obj->id, $app->user->name ),
                    blog_id => $obj->blog_id,
                    author_id => $app->user->id,
                    class => 'link',
                    level => MT::Log::INFO(),
                } );
            }
        } else {
            # $app->run_callbacks( 'cms_post_save.link', $app, $obj, $original );
        }
    }
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        my $app = MT->instance();
        my $plugin = MT->component( 'Link' );
        if ( is_cms( $app ) ) {
            if (! $app->validate_magic ) {
                $app->return_to_dashboard();
                return 0;
            }
            if (! Link::Plugin::_link_permission( $app->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        $obj->SUPER::remove( @_ );
        if ( is_cms( $app ) ) {
            $app->log( {
                message => $plugin->translate( 'Link \'[_1]\' (ID:[_2]) deleted by \'[_3]\'', $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'link',
                level => MT::Log::INFO(),
            } );
            $app->run_callbacks( 'cms_post_delete.link', $app, $obj, $obj );
        }
        my @order = Link::LinkOrder->load( { link_id => $obj->id } );
        for my $ord ( @order ) {
            $ord->remove or die $ord->errstr;
        }
        return 1;
    }
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
        my $plugin = MT->component( 'Link' );
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

sub _nextprev {
    my ( $obj, $direction ) = @_;
    my $r = MT::Request->instance;
    my $nextprev = $r->cache( "link_$direction:" . $obj->id );
    return $nextprev if defined $nextprev;
    $nextprev = $obj->nextprev(
        direction => $direction,
        terms     => { blog_id => $obj->blog_id },
        by        => 'authored_on',
    );
    $r->cache( "link_$direction:" . $obj->id, $nextprev );
    return $nextprev;
}

sub parents {
    my $obj = shift;
    {
        blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        author_id => {
            class => MT->model( 'author' ),
            optional => 1,
            orphanize => 1
        },
    };
}

1;
