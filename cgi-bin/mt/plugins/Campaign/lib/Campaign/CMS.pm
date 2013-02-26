package Campaign::CMS;

use strict;
use MT::Asset;
use MT::Request;
use MT::Log;
use Campaign::Campaign;
use Campaign::CampaignGroup;
use Campaign::CampaignOrder;
use Campaign::Plugin;
use File::Spec;
use MT::Util qw( format_ts trim encode_html );
use MT::I18N qw( substr_text length_text );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( current_ts valid_ts upload site_path file_basename file_extension );

our $plugin_campaign = MT->component( 'Campaign' );

sub _init_request {
    my $app = MT->instance;
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( ( $app->param( 'dialog_view' ) ) || ( MT->version_id =~ /^5\.0/ ) ) {
            $app->add_methods( list_campaign => \&_list_campaign );
            $app->add_methods( list_campaigngroup => \&_list_campaign );
        }
    }
    $app;
}

sub _save_campaign {
    my $app = MT::instance();
    my $type = $app->param( '_type' );
    my $author = $app->user;
    my $blog = $app->blog;
    if (! Campaign::Plugin::_campaign_permission( $app->blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $class = $app->model( $type );
    my $id = $app->param( 'id' );
    my $obj; my $original; my $before;
    my $current_ts = current_ts( $blog );
    if (! $id ) {
        $obj = $class->new;
        $obj->created_on( $current_ts );
    } else {
        $obj = $class->load( $id );
        $original = $obj->clone_all();
        $before = $plugin_campaign->translate( $original->status_text );
    }
    $obj->blog_id( $blog->id );
    $obj->author_id( $author->id ) unless $obj->author_id;
    my @columns = qw( title text memo max_displays max_clicks status url set_period banner_width banner_height editor_select max_uniqdisplays max_uniqclicks );
    for my $column ( @columns ) {
        $obj->$column( $app->param( $column ) );
    }
    my $publishing_on_date = trim( $app->param( 'publishing_on_date' ) );
    my $publishing_on_time = trim( $app->param( 'publishing_on_time' ) );
    my $period_on_date = trim( $app->param( 'period_on_date' ) );
    my $period_on_time = trim( $app->param( 'period_on_time' ) );
    $publishing_on_date =~ s/\-//g;
    $period_on_date =~ s/\-//g;
    $publishing_on_time =~ s/://g;
    $period_on_time =~ s/\://g;
    my $publishing_on = $publishing_on_date . $publishing_on_time;
    my $period_on = $period_on_date . $period_on_time;
    if ( valid_ts( $publishing_on ) ) {
        $obj->publishing_on( $publishing_on );
    } else {
        if (! $obj->publishing_on ) {
            $obj->publishing_on( $current_ts );
        }
    }
    if ( valid_ts( $period_on ) ) {
        $obj->period_on( $period_on );
    } else {
        if (! $obj->period_on ) {
            $obj->period_on( $current_ts );
        }
    }
    if ( my $tags  = $app->param( 'tags' ) ) {
        my @t = split( /,/, $tags );
        $obj->set_tags( @t );
    } else {
        $obj->remove_tags();
    }
    my $filter_result = $app->run_callbacks( 'cms_save_filter.' . $type, $app );
    if ( !$filter_result ) {
        my %param = ();
        $param{error}       = $app->errstr;
        $param{return_args} = $app->param('return_args');
        $app->{ plugin_template_path } = File::Spec->catdir( $plugin_campaign->path, 'tmpl' );
        return $app->forward( "view", \%param );
    }
    my $site_path = site_path( $blog );
    my $banner_directory = $plugin_campaign->get_config_value( 'banner_directory', 'blog:'. $blog->id );
    my $upload_dir = File::Spec->catdir( $site_path, $banner_directory );
    my $basename = trim( $app->param( 'basename' ) );
    my $is_new;
    if (! $obj->id ) {
        my $count = $class->count( { blog_id => $blog->id, basename => $basename } );
        if (! $count ) {
            $obj->basename( $basename );
        }
        $app->run_callbacks( 'cms_pre_save.campaign', $app, $obj, $original )
                          || return $app->errtrans( "Saving [_1] failed: [_2]", 'campaign',
                             $app->errstr );
        $obj->save or die $obj->errstr;
        $is_new = 1;
    } else {
        if ( $obj->basename ne $basename ) {
            my $count = $class->count( { blog_id => $blog->id,
                                         basename => $basename,
                                         id => { not => $obj->id } } );
            if (! $count ) {
                $obj->basename( $basename );
            }
        }
    }
    if ( $app->param( 'image' ) ) {
        my $rename;
        my $file_name = file_basename( $app->param->upload( 'image' ) );
        my $asset_pkg = MT::Asset->handler_for_file( $file_name );
        if ( $asset_pkg eq 'MT::Asset::Image' ) {
            my $original;
            if ( $obj->image_id ) {
                $original = $asset_pkg->load( $obj->image_id );
                if (! $original ) {
                    $rename = 1;
                } else {
                    if ( $original->file_name eq $file_name ) {
                        $rename = 1;
                    }
                }
            }
            unless ( $app->param( 'id' ) ) {
                $rename = 1;
            }
            my %params = ( object  => $obj,
                           author  => $author,
                           label   => $obj->title,
                           rename  => $rename,
                           singler => 1,
                          );
            my $image = upload( $app, $blog, 'image', $upload_dir, \%params );
            if ( defined $image ) {
                $obj->image_id( $image->id );
                if ( $original ) {
                    if ( $original->id != $image->id ) {
                        $original->remove or die $original->errstr;
                    }
                }
            }
        }
    }
    if ( $app->param( 'movie' ) ) {
        my $rename;
        my $file_name = file_basename( $app->param->upload( 'movie' ) );
        my $asset_pkg = MT::Asset->handler_for_file( $file_name );
        if ( ( $asset_pkg eq 'MT::Asset::Video' )
          || ( file_extension( $file_name ) eq 'swf' ) ) {
            my $original;
            if ( $obj->movie_id ) {
                $original = MT::Asset->load( $obj->movie_id );
                if (! $original ) {
                    $rename = 1;
                } else {
                    if ( $original->file_name eq $file_name ) {
                        $rename = 1;
                    }
                }
            }
            my %params = ( object  => $obj,
                           author  => $author,
                           label   => $obj->title,
                           rename  => $rename,
                           singler => 1,
                          );
            my $movie = upload( $app, $blog, 'movie', $upload_dir, \%params );
            if ( defined $movie ) {
                $obj->movie_id( $movie->id );
                if ( $original ) {
                    if ( $original->id != $movie->id ) {
                        $original->remove or die $original->errstr;
                    }
                }
            }
        }
    }
    if (! $is_new ) {
        $app->run_callbacks( 'cms_pre_save.campaign', $app, $obj, $original )
                      || return $app->errtrans( "Saving [_1] failed: [_2]", 'campaign',
                         $app->errstr );
    }
    $obj->save or die $obj->errstr;
    $app->run_callbacks( 'cms_post_save.campaign', $app, $obj, $original );
    if ( $is_new ) {
        $app->log( {
            message => $plugin_campaign->translate( 'Campaign \'[_1]\' (ID:[_2]) created by \'[_3]\'', $obj->title, $obj->id, $author->name ),
            blog_id => $obj->blog_id,
            author_id => $author->id,
            class => 'campaign',
            level => MT::Log::INFO(),
        } );
        $app->add_return_arg( id => $obj->id );
    } else {
        my $after = $plugin_campaign->translate( $obj->status_text );
        if ( $before eq $after ) {
            $app->log( {
                message => $plugin_campaign->translate( 'Campaign \'[_1]\' (ID:[_2]) edited by \'[_3]\'', $obj->title, $obj->id, $author->name ),
                blog_id => $obj->blog_id,
                author_id => $author->id,
                class => 'campaign',
                level => MT::Log::INFO(),
            } );
        } else {
            $app->log( {
                message => $plugin_campaign->translate( 'Campaign \'[_1]\' (ID:[_2]) edited and its status changed from [_3] to [_4] by user \'[_5]\'', $obj->title, $obj->id, $before, $after, $author->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'campaign',
                level => MT::Log::INFO(),
            } );
        }
    }
    $app->add_return_arg( save_changes => 1 );
    $app->call_return;
}

sub _list_campaign {
    my $app = shift;
    my $user = $app->user;
    my $mode = $app->mode;
    my $list_id = $mode;
    $list_id =~ s/^list_//;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if (! defined $app->blog && ! $user->is_superuser() ) {
        return $app->return_to_dashboard( redirect => 1 );
    } else {
        if (! Campaign::Plugin::_campaign_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( ! $app->blog ) {
            # system
        } elsif ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my $all_blogs = $app->blog->blogs;
            for my $blog ( @$all_blogs ) {
                if ( Campaign::Plugin::_campaign_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                }
            }
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
    }
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085;", $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_class } = $blogs{ $obj->blog_id }->class;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = Campaign::Plugin::_campaign_permission( $blogs{ $obj->blog_id } );
                if ( $list_id =~ /group$/ ) {
                    $row->{ can_edit } = Campaign::Plugin::_group_permission( $blogs{ $obj->blog_id } );
                    if ( defined $blogs{ $obj->addfilter_blog_id } ) {
                        $row->{ filter_blogname } = $blogs{ $obj->addfilter_blog_id }->name;
                    }
                }
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $list_id =~ /group$/ ) {
            my $count = Campaign::CampaignOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
        } else {
            if ( my $asset = $obj->image ) {
                require Campaign::Listing;
                my ( $thumbnail, $w, $h ) = Campaign::Listing::__get_thumbnail( $asset );
                my $image_url = $asset->url;
                $row->{ thumbnail } = $thumbnail;
                $row->{ image_url } = $image_url;
                $row->{ asset_alt } = MT->translate( 'Thumbnail image for [_1]', $asset->label );
            }
        }
        my $campaign_author = $obj->author;
        $row->{ author_name } = $campaign_author->name;
    };
    my @campaign_admin = _load_campaign_admin( @blog_ids );
    my @author_loop;
    for my $admin ( @campaign_admin ) {
        $r->cache( 'campaign_author:' . $admin->id, $admin );
        push @author_loop, {
                author_id => $admin->id,
                author_name => $admin->name, };
    }
    my %terms;
    my %param;
    if ( my $query = $app->param( 'query' ) ) {
        if ( my $search_col = $app->param( 'search_col' ) ) {
            $terms{ lc( $search_col ) } = { like => '%' . $query . '%' };
            $param{ query } = $query;
            $param{ search_col } = $search_col;
            my $plugin = MT->component( 'Campaign' );
            $param{ search_col_label } = encode_html( $plugin->translate( $search_col ) );
        }
    }
    if ( $list_id !~ /group$/ ) {
        my @tag_loop;
        require MT::ObjectTag;
#         my @tags = MT::Tag->load( undef,
#                                   { join => MT::ObjectTag->join_on( 'tag_id',
#                                   { blog_id => \@blog_ids, object_datasource => 'campaign', },
#                                   { unique => 1, } ) } );
        my @tags = MT::Tag->load( undef,
                                  { join => MT::ObjectTag->join_on( 'tag_id',
                                                                    { ( @blog_ids ? ( blog_id => \@blog_ids ) : () ),
                                                                      object_datasource => 'campaign',
                                                                    },
                                                                    { unique => 1, }
                                                                  )
                                  }
                                );
        for my $tag ( @tags ) {
            push @tag_loop, {
                tag_name => $tag->name, };
        }
        $param{ tag_loop } = \@tag_loop;
    }
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin_campaign->path, 'tmpl' );
    $param{ list_id } = $list_id;
    $param{ dialog_view } = $app->param( 'dialog_view' );
    $param{ edit_field } = $app->param( 'edit_field' );
    $param{ author_loop }    = \@author_loop;
    $param{ system_view }    = $system_view;
    $param{ website_view }   = $website_view;
    $param{ blog_view }      = $blog_view;
    $param{ LIST_NONCRON }   = 1;
    $param{ saved_deleted }  = 1 if $app->param( 'saved_deleted' );
    $param{ published }      = 1 if $app->param( 'published' );
    $param{ not_published }  = 1 if $app->param( 'not_published' );
    $param{ unpublished }    = 1 if $app->param( 'unpublished' );
    $param{ not_unpublished }= 1 if $app->param( 'not_published' );
    $param{ reserved }       = 1 if $app->param( 'reserved' );
    $param{ not_reserved }   = 1 if $app->param( 'not_reserved' );
    $param{ ended }    = 1 if $app->param( 'ended' );
    $param{ not_ended }= 1 if $app->param( 'not_ended' );
    my $sort_col;
    if ( $list_id =~ /group$/ ) {
        $param{ search_label } = $plugin_campaign->translate( 'Campaign Group' );
        $sort_col = 'created_on';
    } else {
        $param{ search_label } = $plugin_campaign->translate( 'Campaign' );
        $sort_col = 'publishing_on';
    }
    if (! $blog_view ) {
#        $terms{ 'blog_id' } = \@blog_ids;
        if ( @blog_ids ) {
            $terms{ 'blog_id' } = \@blog_ids;
        }
    } else {
        $terms{ 'blog_id' } = $app->blog->id;
    }
    my %args;
    $args{ sort } = $sort_col;
    $args{ direction } = 'descend';
    if ( $app->param( 'dialog_view' ) ) {
        $args{ limit } = 25;
    }
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => \%args,
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub _search_campaign {
    my $app = shift;
    my ( %args ) = @_;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if ( defined $app->blog ) {
        if (! Campaign::Plugin::_campaign_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
        } else {
            $blog_view = 1;
        }
    }
    my $iter;
    if ( $args{ iter } ) {
        $iter = $args{ iter };
    } elsif ( $args{ items } ) {
        $iter = sub { pop @{ $args{ items } } };
    }
    return [] unless $iter;
    my $limit = $args{ limit };
    my $param = $args{ param } || {};
    my @data;
    while ( my $obj = $iter->() ) {
        my $row = $obj->column_values;
        $row->{ object } = $obj;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085;", $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( $obj->blog ) {
                my $blog_name = $obj->blog->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = Campaign::Plugin::_campaign_permission( $obj->blog );
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $app->param( '_type' ) =~ /group$/ ) {
            my $count = Campaign::CampaignOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
        }
        my $campaign_author = $obj->author;
        $row->{ author_name } = $campaign_author->name;
        push @data, $row;
        last if $limit and @data > $limit;
    }
    if ( $app->param( '_type' ) =~ /group$/ ) {
        $param->{ search_label } = $plugin_campaign->translate( 'Campaign Group' );
    } else {
        $param->{ search_label } = $plugin_campaign->translate( 'Campaign' );
    }
    return [] unless @data;
    #$app->config( 'TemplatePath', File::Spec->catdir( $plugin_campaign->path, 'tmpl' ) );
    $param->{ system_view } = 1 unless $app->param( 'blog_id' );
    $param->{ search_replace } = 1;
    $param->{ object_loop } = \@data;
    \@data;
}

sub _view_campaign {
    my $app = shift;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin_campaign->path, 'tmpl' );
    $app->mode( 'edit' );
    return $app->forward( 'edit', @_ );
}

sub _publish_campaigns {
    _status_change( 'published', Campaign::Campaign::RELEASE() );
}

sub _unpublish_campaigns {
    _status_change( 'unpublished', Campaign::Campaign::HOLD() );
}

sub _reserve_campaigns {
    _status_change( 'reserved', Campaign::Campaign::FUTURE() );
}

sub _end_campaigns {
    _status_change( 'ended', Campaign::Campaign::CLOSE() );
}

sub _status_change {
    my ( $param, $status ) = @_;
    my $app = MT::instance();
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @id = $app->param( 'id' );
    my $do;
    for my $campaign_id ( @id ) {
        my $campaign = $app->model( 'campaign' )->load( $campaign_id );
        return $app->errtrans( 'Invalid request.' ) unless $campaign;
        if (! Campaign::Plugin::_campaign_permission( $campaign->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $campaign->status != $status ) {
            my $original = $campaign->clone_all();
            my $before = $plugin_campaign->translate( $original->status_text );
            $campaign->status( $status );
            $campaign->save or die $campaign->errstr;
            if ( $status == Campaign::Campaign::HOLD() ) {
                $app->run_callbacks( 'post_unpublish.campaign', $app, $campaign, $original );
            } elsif ( $status == Campaign::Campaign::RELEASE() ) {
                $app->run_callbacks( 'post_publish.campaign', $app, $campaign, $original );
            } elsif ( $status == Campaign::Campaign::FUTURE() ) {
                $app->run_callbacks( 'post_reserved.campaign', $app, $campaign, $original );
            } elsif ( $status == Campaign::Campaign::CLOSE() ) {
                $app->run_callbacks( 'post_close.campaign', $app, $campaign, $original );
            }
            my $after = $plugin_campaign->translate( $campaign->status_text );
            $app->log( {
                message => $plugin_campaign->translate( 'Campaign \'[_1]\' (ID:[_2]) edited and its status changed from [_3] to [_4] by user \'[_5]\'', $campaign->title, $campaign->id, $before, $after, $app->user->name ),
                blog_id => $campaign->blog_id,
                author_id => $app->user->id,
                class => 'campaign',
                level => MT::Log::INFO(),
            } );
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( $param => 1 );
    } else {
        $app->add_return_arg( 'not_' . $param => 1 );
    }
    $app->call_return;
}

sub _load_campaign_admin {
    my @blog_id = @_;
    push ( @blog_id, 0 );
    my $author_class = MT->model( 'author' );
    my %terms1 = ( blog_id => \@blog_id, permissions => { like => "\%'administer\%" } );
    my @admin = $author_class->load(
        { type => MT::Author::AUTHOR(), },
        { join => [ 'MT::Permission', 'author_id',
            \%terms1,
            { unique => 1 } ],
        }
    );
    my @author_id;
    for my $author ( @admin ) {
        push ( @author_id, $author->id );
    }
    my %terms2 = ( blog_id => \@blog_id, permissions => { like => "\%'manage_campaign'\%" } );
    my @campaign_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @campaign_admin );
    return @admin;
}

1;