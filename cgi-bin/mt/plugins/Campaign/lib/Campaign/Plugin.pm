package Campaign::Plugin;

use strict;

use File::Spec;
use MT::Util qw( offset_time_list format_ts epoch2ts ts2epoch encode_js );
use MT::I18N qw( substr_text length_text );
use lib qw(addons/PowerCMS.pack/lib);
use PowerCMS::Util qw( current_ts file_extension build_tmpl is_user_can );
# use Campaign::Campaign;
# use Campaign::CampaignGroup;
# use Campaign::CampaignOrder;

our $plugin_campaign = MT->component( 'Campaign' );

sub _pre_run {
    my ( $cb, $app ) = @_;
    my $menus = MT->registry( 'applications', 'cms', 'menus' );
    if ( MT->version_id =~ /^5\.0/ ) {
        $menus->{ 'campaign:list_campaign' }->{ mode } = 'list_campaign';
        $menus->{ 'campaign:list_campaigngroup' }->{ mode } = 'list_campaigngroup';
        $menus->{ 'campaign:list_campaign' }->{ view } = [ 'blog', 'website' ];
        $menus->{ 'campaign:list_campaigngroup' }->{ view } = [ 'blog', 'website' ];
    }
}

sub _edit_campaign {
    my ( $cb, $app, $param, $tmpl ) = @_;
    require MT::Request;
    my $type  = $app->param( '_type' );
    my $class = $app->model( $type );
    my $blog  = $app->blog;
    if (! $blog ) {
        $app->return_to_dashboard();
    }
    if (! _campaign_permission( $app->blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $r = MT::Request->instance;
    my $id = $app->param( 'id' );
    if ( $id ) {
        my $obj = $class->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $blog->id ) {
            $app->return_to_dashboard( permission => 1 );
        }
        my $publishing_on = $obj->publishing_on;
        my $period_on = $obj->period_on;
        my $next = $obj->_nextprev( 'next' );
        if ( $next ) {
            $param->{ next_campaign_id } = $next->id;
        }
        my $previous = $obj->_nextprev( 'previous' );
        if ( $previous ) {
            $param->{ previous_campaign_id } = $previous->id;
        }
        my @tags = $obj->tags;
        my $tag = join( ',', @tags );
        $param->{ tags } = $tag;
        $param->{ publishing_on_date } = format_ts( '%Y-%m-%d', $publishing_on );
        $param->{ publishing_on_time } = format_ts( '%H:%M:%S', $publishing_on );
        $param->{ period_on_date } = format_ts( '%Y-%m-%d', $period_on );
        $param->{ period_on_time } = format_ts( '%H:%M:%S', $period_on );
        my $banner_width  = $obj->banner_width;
        my $banner_height = $obj->banner_height;
        if ( $obj->image_id ) {
            require MT::Asset::Image;
            my $image = MT::Asset::Image->load( $obj->image_id );
            if ( $image ) {
                $r->cache( 'campaign_image:' . $obj->image_id, $image );
                $param->{ orig_image_url } = $image->url;
                my ( $url, $w, $h ) = $obj->banner;
                $param->{ image_url }    = $url;
                $param->{ image_width }  = $w;
                $param->{ image_height } = $h;
                $param->{ image_label }  = $image->label;
            }
        }
        if ( $obj->movie_id ) {
            require MT::Asset;
            my $movie = MT::Asset->load( $obj->movie_id );
            if ( $movie ) {
                $r->cache( 'campaign_movie:' . $obj->movie_id, $movie );
                my $file_extension = file_extension( $movie->url );
                $param->{ movie_url } = $movie->url;
                $param->{ movie_label }  = $movie->label;
                $param->{ movie_extension } = $file_extension;
                $param->{ movie_mime_type } = $movie->mime_type;
            }
        }
    } else {
        $param->{ status } = $plugin_campaign->get_config_value( 'default_status', 'blog:'. $blog->id );
        $param->{ url } = 'http://';
        my @tl = offset_time_list( time, $app->blog );
        my $ts_date = sprintf '%04d-%02d-%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
        my $ts_time = sprintf '%02d:%02d:%02d', @tl[2,1,0];
        my $current_ts = sprintf '%04d%02d%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
        $current_ts .= '000000';
        $param->{ publishing_on_date } = $ts_date;
        $param->{ publishing_on_time } = $ts_time;
        my $default_campaign_period = $plugin_campaign->get_config_value( 'default_campaign_period', 'blog:'. $blog->id );
        $current_ts = _end_date( $blog, $current_ts, $default_campaign_period );
        $ts_date = substr( $current_ts, 0, 4 ) . '-' . substr( $current_ts, 4, 2 ) . '-' . substr( $current_ts, 6, 2 );
        $param->{ period_on_date } = $ts_date;
        $param->{ period_on_time } = $ts_time;
        my $default_banner_width  = $plugin_campaign->get_config_value( 'default_banner_width', 'blog:'. $blog->id );
        my $default_banner_height = $plugin_campaign->get_config_value( 'default_banner_height', 'blog:'. $blog->id );
        $param->{ banner_width } = $default_banner_width;
        $param->{ banner_height } = $default_banner_height;
    }
    my $max_banner_size = $plugin_campaign->get_config_value( 'max_banner_size', 'blog:'. $blog->id );
    my $min_banner_size = $plugin_campaign->get_config_value( 'min_banner_size', 'blog:'. $blog->id );
    $param->{ max_banner_size } = $max_banner_size;
    $param->{ min_banner_size } = $min_banner_size;
    $param->{ saved } = $app->param( 'save_changes' );
    $param->{ search_label } = $plugin_campaign->translate( 'Campaign' );
    $param->{ screen_group } = 'campaign';
    my $editor_style_css = $plugin_campaign->get_config_value( 'editor_style_css', 'blog:'. $blog->id );
    my %args = ( blog => $app->blog );
    $editor_style_css = build_tmpl( $app, $editor_style_css, \%args );
    $param->{ editor_style_css } = $editor_style_css;
    $param->{ theme_advanced_buttons1 } = $plugin_campaign->get_config_value( 'theme_advanced_buttons1', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons2 } = $plugin_campaign->get_config_value( 'theme_advanced_buttons2', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons3 } = $plugin_campaign->get_config_value( 'theme_advanced_buttons3', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons4 } = $plugin_campaign->get_config_value( 'theme_advanced_buttons4', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons5 } = $plugin_campaign->get_config_value( 'theme_advanced_buttons5', 'blog:'. $blog->id );
    $param->{ use_wysiwyg } = $plugin_campaign->get_config_value( 'use_wysiwyg', 'blog:'. $blog->id );
    $param->{ lang } = $app->user->preferred_language;
    $param->{ return_args } = _force_view_mode_return_args( $app );
    $param->{ edit_screen } = 1;
    $param->{ screen_class } = 'edit-entry';
    # Add <mtapp:fields> after description
    require CustomFields::App::CMS;
    CustomFields::App::CMS::add_app_fields( $cb, $app, $param, $tmpl, 'memo', 'insertAfter' );
}

sub _edit_campaign_out {
    my ( $cb, $app, $tmpl, $param ) = @_;
    # $$tmpl =~ s/(<div\sid="customfield_.*?\-field"\sclass="field\s)[(?:required\s)]*field\-top\-label(\s">)/$1field-left-label$2/gi;
}

sub _edit_campaigngroup {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $type  = $app->param( '_type' );
    my $class = $app->model( $type );
    my $blog  = $app->blog;
    if (! $blog ) {
        $app->return_to_dashboard();
    }
    if (! _group_permission( $app->blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $id = $app->param( 'id' );
    my $filter = $app->param( 'filter' );
    my $filter_tag = $app->param( 'filter_tag' );
    my $obj;
    if ( $id ) {
        $obj = $class->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $blog->id ) {
            $app->return_to_dashboard( permission => 1 );
        }
    }
    my %blogs;
    my @weblog_loop;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my %terms;
    my %args;
    require Campaign::CampaignOrder;
    if (! defined $app->blog ) {
        $app->return_to_dashboard( redirect => 1 );
    } else {
        if (! _group_permission( $app->blog ) ) {
            $app->return_to_dashboard( redirect => 1 );
        }
        if ( $app->blog->class eq 'website' ) {
            push @weblog_loop, {
                    weblog_id => $app->blog->id,
                    weblog_name => $app->blog->name, };
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
            for my $blog ( @all_blogs ) {
                if ( _group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                    push @weblog_loop, {
                            weblog_id => $blog->id,
                            weblog_name => $blog->name, };
                }
            }
            $param->{ weblog_loop } = \@weblog_loop;
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
        if (! $blog_view ) {
            $terms{ 'blog_id' } = \@blog_ids;
        } else {
            $terms{ 'blog_id' } = $app->blog->id;
        }
        if ( $filter && ( $filter eq 'active' ) ) {
            my $ts = current_ts( $app->blog );
            $terms{ publishing_on } = { '<' => $ts };
            $terms{ period_on }     = { '>' => $ts };
            $terms{ status } = 2;
        }
        my @campaigns;
        if ( $filter && ( $filter eq 'tag' ) && $filter_tag ) {
            require MT::Tag;
            my $tag = MT::Tag->load( { name => $filter_tag }, { binary => { name => 1 } } );
            if ( $tag ) {
                require MT::ObjectTag;
                $args { 'join' } = [ 'MT::ObjectTag', 'object_id',
                           { tag_id  => $tag->id,
                             blog_id => \@blog_ids,
                             object_datasource => 'campaign' }, ];
                @campaigns = MT->model( 'campaign' )->load( \%terms, \%args );
            }
        } else {
            @campaigns = MT->model( 'campaign' )->load( \%terms, \%args );
        }
        my @item_loop;
        for my $campaign ( @campaigns ) {
            my $add_item = 1;
            if ( $id ) {
                my $item = Campaign::CampaignOrder->load( { group_id => $id, campaign_id => $campaign->id } );
                $add_item = 0 if defined $item;
            }
            if ( $add_item ) {
                my $weblog_name = '';
                if (! $blog_view ) {
                    $weblog_name = $blogs{ $campaign->blog_id }->name;
                    $weblog_name = " ($weblog_name)";
                }
                my $asset = $campaign->image;
                my ( $thumbnail, $w, $h );
                my $asset_alt;
                my $asset_url;
                if ( $asset ) {
                    if ( $asset->class eq 'image' ) {
                        ( $thumbnail, $w, $h ) = __get_thumbnail( $asset );
                        my $asset_label = $asset->label;
                        $asset_url = $asset->url;
                        $asset_label = substr_text( $asset_label, 0, 15 ) . ( length_text( $asset_label ) > 15 ? '...' : '' );
                        $asset_alt = MT->translate( 'Thumbnail image for [_1]', $asset_label );
                    }
                }
                push @item_loop, {
                        id => $campaign->id,
                        item_title => $campaign->title . $weblog_name,
                        campaign_url => $campaign->url,
                        can_edit => _campaign_permission( $campaign->blog ),
                        status => $campaign->status,
                        thumbnail => $thumbnail,
                        asset_alt => $asset_alt,
                        asset_url => $asset_url,
                        weblog_id => $campaign->blog_id, };
            }
        }
        $param->{ item_loop } = \@item_loop;
        if ( $id ) {
            my $args = { 'join' => [ 'Campaign::CampaignOrder', 'campaign_id',
                       { group_id => $id, },
                       { sort => 'order',
                         direction => 'ascend',
                       } ] };
            my @campaigns = MT->model( 'campaign' )->load( \%terms, $args );
            my @group_loop;
            for my $campaign ( @campaigns ) {
                my $weblog_name = '';
                if (! $blog_view ) {
                    $weblog_name = $blogs{ $campaign->blog_id }->name;
                    $weblog_name = " ($weblog_name)";
                }
                my $asset = $campaign->image;
                my ( $thumbnail, $w, $h );
                my $asset_alt;
                my $asset_url;
                if ( $asset ) {
                    if ( $asset->class eq 'image' ) {
                        ( $thumbnail, $w, $h ) = __get_thumbnail( $asset );
                        my $asset_label = $asset->label;
                        $asset_url = $asset->url;
                        $asset_label = substr_text( $asset_label, 0, 15 ) . ( length_text( $asset_label ) > 15 ? '...' : '' );
                        $asset_alt = MT->translate( 'Thumbnail image for [_1]', $asset_label );
                    }
                }
                push @group_loop, {
                        id => $campaign->id,
                        item_title => $campaign->title . $weblog_name,
                        campaign_url => $campaign->url,
                        can_edit => _campaign_permission( $campaign->blog ),
                        status => $campaign->status,
                        thumbnail => $thumbnail,
                        asset_alt => $asset_alt,
                        asset_url => $asset_url,
                        weblog_id => $campaign->blog_id, };
            }
            $param->{ group_loop } = \@group_loop;
        }
    }
    my @groups = Campaign::CampaignGroup->load( { blog_id => $blog->id } );
    if ( @groups ) {
        my @names;
        for my $g ( @groups ) {
            if ( $id != $g->id ) {
                push ( @names, "'" . encode_js ( $g->name ) . "'" );
            }
        }
        my $names_array = join( ' , ', @names );
        $param->{ names_array } = $names_array if $names_array;
    }
    $param->{ filter } = $filter;
    $param->{ filter_tag } = $filter_tag;
    $param->{ saved } = $app->param( 'saved' );
    $param->{ search_label } = $plugin_campaign->translate( 'Campaign' );
    $param->{ screen_group } = 'campaign';
    $param->{ search_type } = 'campaign';
    $param->{ return_args } = _force_view_mode_return_args( $app );
}

sub _force_view_mode_return_args {
    my $app = shift;
    my $return = $app->make_return_args;
    $return =~ s/edit/view/;
    return $return;
}

sub _asset_insert {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $edit_field = $app->param( 'edit_field' );
    return unless $edit_field;
    if ( $edit_field =~ /^campaign_(.*$)/ ) {
        $edit_field = $1;
        my $pointer_field = $tmpl->getElementById( 'insert_script' );
        $pointer_field->innerHTML( qq{window.parent.custom_insertHTML( '<mt:var name="upload_html" escape="js">', '$edit_field' );} );
    }
}

sub _list_tag {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( $app->param( 'filter_key' ) eq 'campaign' ) {
        $param->{ filter_label } = $plugin_campaign->translate( 'Tags with campaigns' );
        $param->{ screen_group } = 'campaign';
    }
    my $list_filters = $param->{ list_filters };
            push @$list_filters,
            {
              key   => 'campaign',
              label => $plugin_campaign->translate( 'Tags with campaigns' ),
            };
    $param->{ list_filters } = $list_filters;
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if (! $app->param( 'id' ) ) {
        if ( my $blog = $app->blog ) {
            if ( my $group_id = $app->param( 'campaigngroup_id' ) ) {
                my $group = Campaign::CampaignGroup->load( $group_id );
                if ( $group ) {
                    my $group_name = $group->name;
                    my $group_id = $group->id;
                    my $template = $plugin_campaign->get_config_value( 'default_module_mtml', 'blog:'. $blog->id );
                    if (! $template ) {
                        require Campaign::Tools;
                        $template = Campaign::Tools::_default_module_mtml();
                    }
                    $template =~ s/\$group_name/$group_name/isg;
                    $template =~ s/\$group_id/$group_id/isg;
                    my $hidden_field = qq{<input type="hidden" name="campaigngroup_id" value="$group_id" />};
                    $param->{ name } = $plugin_campaign->translate( 'Campaign Group' ) . ' : ' . $group_name;
                    $param->{ text } = $template;
                    my $pointer_field = $tmpl->getElementById( 'title' );
                    my $innerHTML = $pointer_field->innerHTML;
                    $pointer_field->innerHTML( $innerHTML . $hidden_field );
                }
            }
        }
    }
}

sub _cms_post_save_template {
    my ( $cb, $app, $obj, $original ) = @_;
    if (! $original->id ) {
        my $blog = $app->blog;
        if ( defined $blog ) {
            my $type = $obj->type;
            if ( $type ne 'custom' ) {
                return 1;
            }
            my $group_id = $app->param( 'campaigngroup_id' );
            if ( $group_id ) {
                my $group = Campaign::CampaignGroup->load( $group_id );
                if ( $group ) {
                    $group->template_id( $obj->id );
                    $group->save or die $group->errstr;
                }
            }
        }
    }
    return 1;
}

sub _cms_post_delete_template {
    my ( $cb, $app, $obj, $original ) = @_;
    my $type = $obj->type;
    if ( $type ne 'custom' ) {
        return 1;
    } else {
        my $group = Campaign::CampaignGroup->load( { template_id => $obj->id } );
        if ( $group ) {
            $group->template_id( undef );
            $group->save or die $group->errstr;
        }
    }
    return 1;
}

sub _add_tags_to_campaign {
    my $app = MT::instance();
    my $itemset_action_input = $app->param( 'itemset_action_input' );
    my $done = 0;
    if ( $itemset_action_input ) {
        require MT::Tag;
        my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } ) || ',';
        my @tag_names = MT::Tag->split( $tag_delim, $itemset_action_input );
        my $plugin = MT->component( 'Campaign' );
        if ( $app->param( 'all_selected' ) ) {
            $app->setup_filtered_ids;
        }
        my @id = $app->param( 'id' );
        require Campaign::Campaign;
        for my $campaign_id ( @id ) {
            my $campaign = $app->model( 'campaign' )->load( $campaign_id );
            return $app->errtrans( 'Invalid request.' ) unless $campaign;
            if (! _campaign_permission( $campaign->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            $campaign->add_tags( @tag_names );
            $campaign->save or die $campaign->errstr;
            $done++;
        }
    }
    if ( $done ) {
        $app->add_return_arg( 'add_tags_to_campaign' => 1 );
    } else {
        $app->add_return_arg( 'not_add_tags_to_campaign' => 1 );
    }
    $app->call_return;
}

sub _remove_tags_to_campaign {
    my $app = MT::instance();
    my $itemset_action_input = $app->param( 'itemset_action_input' );
    my $done = 0;
    if ( $itemset_action_input ) {
        require MT::Tag;
        my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } ) || ',';
        my @tag_names = MT::Tag->split( $tag_delim, $itemset_action_input );
        my $plugin = MT->component( 'Campaign' );
        if ( $app->param( 'all_selected' ) ) {
            $app->setup_filtered_ids;
        }
        my @id = $app->param( 'id' );
        require Campaign::Campaign;
        for my $campaign_id ( @id ) {
            my $campaign = $app->model( 'campaign' )->load( $campaign_id );
            return $app->errtrans( 'Invalid request.' ) unless $campaign;
            if (! _campaign_permission( $campaign->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            $campaign->remove_tags( @tag_names );
            $campaign->save or die $campaign->errstr;
            $done++;
        }
    }
    if ( $done ) {
        $app->add_return_arg( 'remove_tags_to_campaign' => 1 );
    } else {
        $app->add_return_arg( 'not_remove_tags_to_campaign' => 1 );
    }
    $app->call_return;
}

sub _cms_save_filter_campaign {
    my ( $eh, $app ) = @_;
    local $app->{ component } = 'Commercial';
    if ( MT->component( 'Commercial' )->version >= 1.62 ) {
        unshift( @_, 'campaign' );
    }
    require CustomFields::App::CMS;
    CustomFields::App::CMS::CMSSaveFilter_customfield_objs( @_ );
}

sub _end_date {
    my ( $blog, $ts, $day ) = @_;
    $ts = ts2epoch( $blog, $ts );
    $ts += 86400 * $day;
    return epoch2ts( $blog, $ts );
}

sub _campaign_permission {
    my ( $blog ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog = $app->blog unless $blog;
    return 1 if $user->is_superuser;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_campaign'%" } );
        require MT::Permission;
        my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] );
        if ( $perms ) {
            return 1;
        } else {
            return 0;
        }
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_campaign' ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub _group_permission {
    my ( $blog ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog = $app->blog unless $blog;
    return 1 if $user->is_superuser;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_campaigngroup'%" } );
        require MT::Permission;
        my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] );
        if ( $perms ) {
            return 1;
        } else {
            return 0;
        }
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_campaigngroup' ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub __get_thumbnail {
    my $asset = shift;
    my %args;
    $args{ Square } = 1;
    if ( $asset->image_height > $asset->image_width ) {
        $args{ Width } = 28;
    } else {
        $args{ Height } = 28;
    }
    return $asset->thumbnail_url( %args );
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;
    
    my %campaigns;
    for my $key ( keys %$objects ) {
        if ( $key =~ /^Campaign::Campaign#(\d+)$/ ) {
            $campaigns{ $1 } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        MT->translate(
            "Restoring campaign associations found in custom fields ...",
        ),
        'cf-restore-object-campaign'
    );
    
    my $r = MT::Request->instance();
    for my $campaign ( values %campaigns ) {
        my $iter = CustomFields::Field->load_iter( { blog_id  => [ $campaign->blog_id, 0 ],
                                                     type => [ 'campaign', 'campaign_multi', 'campaign_group' ],
                                                   }
                                                 );
        while ( my $field = $iter->() ) {
            my $class = MT->model( $field->obj_type );
            next unless $class;
            my @related_objects = $class->load( $class->has_column( 'blog_id' ) ? { blog_id => $campaign->blog_id } : undef );
            my $column_name = 'field.' . $field->basename;
            for my $related_object ( @related_objects ) {
                my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                next if $r->cache( $cache_key );
                my $value = $related_object->$column_name;
                my $restored_value;
                if ( $field->type eq 'campaign' ) {
                    my $restored_obj = $objects->{ 'Campaign::Campaign#' . $value };
                    if ( $restored_obj ) {
                        $restored_value = $restored_obj->id;
                    }
                } elsif ( $field->type eq 'campaign_multi' ) {
                    my @values = split( /,/, $value );
                    my @new_values;
                    for my $backup_id ( @values ) {
                        next unless $backup_id;
                        next unless $objects->{ 'Campaign::Campaign#' . $backup_id };
                        my $restored_obj = $objects->{ 'Campaign::Campaign#' . $backup_id };
                        push( @new_values, $restored_obj->id );
                    }
                    $restored_value = join( ',', @new_values );
                } elsif ( $field->type eq 'campaign_group' ) {
                    my $restored_obj = $objects->{ 'Campaign::CampaignGroup#' . $value };
                    if ( $restored_obj ) {
                        $restored_value = $restored_obj->id;
                    }
                }
                $related_object->$column_name( $restored_value );
                $related_object->save or die $related_object->errstr;
                $r->cache( $cache_key, 1 );
            }
        }
    }                                 
    $callback->( MT->translate( "Done." ) . "\n" );
}

1;
