package PowerCMS::Plugin;
use strict;

use PowerCMS::Util qw(
    is_cms plugin_template_path is_user_can write2file build_tmpl chomp_dir
    current_user can_edit_entry current_date current_time current_blog
    read_from_file
);

sub initializer {
    require PowerCMS::BackupRestore;
    require PowerCMS::OverRide;
}

sub _cb_take_down_reset_environmental_variables {
    return unless $ENV{FAST_CGI};
    my $app = MT->instance;
    my $cfg = $app->config;
    my $c = $app->find_config;
    $cfg->read_config( $c );
    $cfg->read_config_db();
}

sub _cb_take_down_reset_request {
    return unless $ENV{FAST_CGI};
    my $r = MT::Request->instance;
    $r->reset();
}

sub _cb_take_down_reset_plugin_switch {
    my $app = MT->instance;
    return 1 unless $app->mode eq 'plugin_control';
    my $plugin = MT->component( 'PowerCMSUpgrade' );
    my $switch = MT->config( 'PluginSwitch' ) || {};
    $switch->{ $plugin->{ plugin_sig } } = 1;
    MT->config( 'PluginSwitch', $switch, 1 );
    MT->config->save_config();
}

sub _cb_cms_post_save_field {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 unless MT->config->LCCustomFieldTagName;
    if ( my $tag = $obj->tag ) {
        $obj->tag( lc $tag );
        $obj->save or die $obj->errstr;
    }
    1;
}

sub _cb_tp_edit_category {
    my ( $cb, $app, $param, $tmpl ) = @_;
    $param->{ screen_group } = $app->param( '_type' );
}

sub _cb_ts_header_style_for_duplicate {
    my ( $cb, $app, $tmpl ) = @_;
    if ( $app->mode eq 'list' ) {
        if ( $app->param( '_type' ) && $app->param( '_type' ) =~ /^(?:entry|page)$/ ) {
            my $insert = <<'STYLE';
<style type="text/css">
    .col.head.duplicate {
        width:4em;
        text-align:center;
    }
    td.col.duplicate {
        text-align:center;
    }
    .col.head.comment_count {
        width:6.5em;
    }
</style>
STYLE
            $$tmpl =~ s/(<mt:var name="html_head">)/$1$insert/;
        }
    }
}

sub _cb_tp_edit_entry_params_for_duplicate {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $duplicate = $app->param( 'duplicate' );
    if ( $duplicate ) {
        my $user = current_user( $app );
        my $blog = current_blog( $app );
        $param->{ new_object } = 1;
        $param->{ author_id } = $user->id;
        $param->{ authored_on_date } = current_date( $blog );
        $param->{ authored_on_time } = current_time( $blog );
        if ( is_user_can( $blog, $user, 'publish_post' ) ) {
            $param->{ status } = $blog->status_default;
        } else {
            $param->{ status } = MT::Entry::HOLD();
            $param->{ status_draft } = 1;
            $param->{ status_publish } = 0;
        }
        $param->{ basename } = '';
    }
}

# sub _cb_tp {
#     my ( $cb, $app, $param, $tmpl ) = @_;
#     my $top_nav_loop = $param->{ top_nav_loop } or return 1;
#     for my $top_nav ( @$top_nav_loop ) {
#         if ( $top_nav->{ id } eq 'tools' ) {
#             my $sub_nav_loop = $top_nav->{ sub_nav_loop };
#             my @new_sub_nav_loop = grep {
#                 $_->{ id } ne 'tools:start_backup'
#                     && $_->{ id } ne 'tools:restore'
#             } @$sub_nav_loop;
#             $top_nav->{ sub_nav_loop } = \@new_sub_nav_loop;
#         }
#     }
# }

sub _cb_cms_filtered_list_param_entry {
    my ( $cb, $app, $param, $objs ) = @_;
    my $user = current_user( $app );
    my $i = 0;
    for my $obj ( @$objs ) {
        my $row = $param->{ objects }->[ $i++ ];
        unless ( can_edit_entry( $obj, $user ) ) {
            $row->[ 0 ] = 0;
        }
    }
}

sub _cfg_prefs_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerCMS' );
    my $pointer_field = $tmpl->getElementById( 'description' );
    my $nodeset = $tmpl->createElement( 'app:setting', { id => 'exclude_search',
                                                         label => $plugin->translate( 'Search' ),
                                                         required => 0, } );
    my $label = $plugin->translate( 'Excludes search from other blog.' );
    my $innerHTML = <<__EOF__;
    <div><label>
    <input type="checkbox" name="exclude_search" id="exclude_search" value="1"
                                             <mt:if name="exclude_search">checked="checked"</mt:if> />
    $label</label><input type="hidden" name="exclude_search" value="0" />
    </div>
__EOF__
    $nodeset->innerHTML( $innerHTML );
    $tmpl->insertAfter( $nodeset, $pointer_field );
}

sub refresh_cache {
    my $app = shift;
    if (! $app->user->is_superuser ) {
        $app->return_to_dashboard( permission => 1 );
    }
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    MT->refresh_cache();
    $app->add_return_arg( refresh_cache => 1 );
    $app->call_return();
}

sub _header_menu {
    my ( $cb, $app, $tmpl ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'plugin-headertitle-init' );
    return 1 if $cache;
    $r->cache( 'plugin-headertitle-init', 1 );
    __system_overview( $cb, $app, $tmpl );
    my $tmpl_else = <<'MTML';
    <mt:else>
    <li id="view-site" class="nav-link"><a href="<$mt:var name="website_url"$>" title="<__trans phrase="View Site">" target="<__trans phrase="_external_link_target">"><span><__trans phrase="View"></span></a></li>
    </mt:else>
MTML
    $$tmpl =~ s{(<li id="view-site".*?)(</mt:if>)}{$1$tmpl_else$2}si;
    if ( $app->param( 'dialog' ) ) {
        return;
    }
    if ( $$tmpl =~ m!(<h1\s.*?</h1>)!is ) {
        my $header = $1;
        my $version_id = $app->version_id;
        $version_id =~ s/(?:[.0-9]+|-ja)//g;
        my $left = 200;
        if ( $version_id ) {
            $left += 40;
        }
        $left .= 'px';
        $$tmpl =~ s!<h1\s.*?</h1>!!is;
        $header =~ s/<h1/<h1 style="left:$left"/;
        $$tmpl =~ s!(<div\sid="container")!$header$1!;
        my $MenuBarNav = '<!-- /Menu Bar Nav-->';
        $$tmpl =~ s!<a href="#" class="toggle-link.*?</a>!!is;
        my $toggle_nav = '<mt:if name="display_options"><div class="toggle-link-wrapper"><a href="#" class="toggle-link detail-link"><__trans phrase="Display Options"> <span class="toggle-button"><img src="<mt:var name="static_uri">images/arrow/arrow-toggle.png" /></span></a></div></mt:if>';
        $$tmpl =~ s!($MenuBarNav)! $toggle_nav$1!si;
        $$tmpl =~ s!<mt:if\sname="object_nav">.*?</mt:if>!!is;
        my $object_nav = '<div id="object-nav-wrapper"><mt:if name="object_nav"><mt:var name="object_nav"></mt:if></div>';
        $$tmpl =~ s!($MenuBarNav)! $object_nav$1!si;
        $$tmpl =~ s!(id="content-body")!$1 style="margin-top:1px;"!;
        $$tmpl =~ s!(id="display-options")!$1 style="margin-top:-7px;"!;
    }
    my $plugin = MT->component( 'PowerCMS' );
    require File::Spec;
    my $plugin_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'Compact.tmpl' );
    my $new = qq{<mt:include name="$plugin_tmpl" component="PowerCMS">};
    $$tmpl =~ s/(<mt:var name="html_head">)/$new$1/;
    return 1;
}

sub _footer_source {
    my ( $cb, $app, $tmpl ) = @_;
    if ($app->version_number >= 5.2) {
        return 1;
    }
    my $id = $app->component(__PACKAGE__ =~ /^([^:]+)/)->id;
    $$tmpl =~ s{(<__trans phrase="http://www\.sixapart\.com/movabletype/">)}
               {<mt:if name="id" eq="$id"><__trans phrase="http://alfasado.net/"><mt:else>$1</mt:if>};
}

sub __system_overview {
    my ( $cb, $app, $tmpl ) = @_;
    my $user = $app->user;
    return unless $user;
    my $perms = $user->permissions;
    return unless $perms;
    my $insert = '';
    unless ( MT->config->DisableSystemMenu ) {
        if ( $perms->can_view_log ) {
            $insert .= <<'MTML';
            <li><a href="<$mt:var name="mt_url"$>?__mode=list&amp;_type=log&amp;blog_id=0" title="<__trans phrase="View Activity Log">"><__trans phrase="View Activity Log"></a></li>
MTML
        }
        if ( $perms->can_manage_plugins ) {
            $insert .= <<'MTML';
            <li><a href="<$mt:var name="mt_url"$>?__mode=cfg_plugins&amp;blog_id=0" title="<__trans phrase="Plugin Settings">"><__trans phrase="Plugin Settings"></a></li>
MTML
        }
        if ( $perms->can_edit_templates ) {
            $insert .= <<'MTML';
            <li><a href="<$mt:var name="mt_url"$>?__mode=list_template&amp;blog_id=0" title="<__trans phrase="Global Templates">"><__trans phrase="Global Templates"></a></li>
MTML
        }
        if ( $user->is_superuser ) {
            $insert .= <<'MTML';
            <li><a href="<$mt:var name="mt_url"$>?__mode=list&amp;_type=author&amp;blog_id=0" title="<__trans phrase="Manage Users">"><__trans phrase="Manage Users"></a></li>
            <li><a href="<$mt:var name="mt_url"$>?__mode=search_replace&amp;blog_id=0" title="<__trans phrase="Search &amp; Replace">"><__trans phrase="Search &amp; Replace"></a></li>
            <li><a href="<$mt:var name="mt_url"$>?__mode=cfg_system_general&amp;blog_id=0" title="<__trans phrase="General Settings">"><__trans phrase="General Settings"></a></li>
            <li><a href="<$mt:var name="mt_url"$>?__mode=list&amp;_type=website&amp;blog_id=0" title="<__trans phrase="Manage Website">"><__trans phrase="Manage Website"></a></li>
            <li><a href="<$mt:var name="mt_url"$>?__mode=list&amp;_type=role&amp;blog_id=0" title="<__trans phrase="Roles">"><__trans phrase="Roles"></a></li>
MTML
            if ( MT->component( 'Commercial' ) ) {
                $insert .= <<'MTML';
            <__trans_section component="Commercial">
            <li><a href="<$mt:var name="mt_url"$>?__mode=list&amp;_type=field&amp;blog_id=0" title="<__trans phrase="Custom Fields">"><__trans phrase="Custom Fields"></a></li>
            </__trans_section>
MTML
                $insert .= <<'MTML';
            <li><a href="<$mt:var name="mt_url"$>?__mode=tools&amp;blog_id=0" title="<__trans phrase="System Information">"><__trans phrase="System Information"></a></li>
MTML
            }
        }
    }
    if ( $insert ) {
        $insert = <<'MTML' . $insert;
        <li id="extended_system_menu" class="extended_menu"><a href="<$mt:var name="mt_url"$>?__mode=dashboard&amp;blog_id=0" id="extended_system_menu" class="extended_system_menu"><__trans_section component="PowerCMS"><__trans phrase="System Overview"></__trans_section></a>
        <ul id="extended_system_menu_ul" class="extended_menu_ul">
MTML
    }
    # Bookmark
    my $bookmark_label = '<mt:setvarblock name="bookmark_label" mteval="1"><mt:if name="html_title"><$mt:var name="html_title"$><mt:else><$mt:var name="page_title"$></mt:if><mt:if name="blog_name"> - <$mt:var name="blog_name" escape="html"$></mt:if></mt:setvarblock>';
    my $bookmark = $bookmark_label . '<__trans_section component="PowerCMS"><li id="bookmarks_menu" class="extended_menu"><a href="<$mt:var name="mt_url"$>?__mode=shortcut_dialog<mt:ignore>&amp;bookmark_label=<mt:var name="bookmark_label" translate_templatized="1" escape="url"></mt:ignore>&amp;bookmark_url=<MTThisURL escape="url">" id="bookmarks_menu_a" class="extended_menu_a mt-open-dialog" title="<__trans phrase="Add to Bookmark">"><__trans phrase="Bookmark"></a></__trans_section>';
    $bookmark .= qq{<ul id="bookmarks_menu_ul" class="extended_menu_ul"><mt:UserBookmarks lastn="20">\n};
    # Bookmarks loop
    $bookmark .= qq{<li id="menu_bk_item_<mt:var name="__counter__" escape="html">"><a href="<mt:var name="url" escape="html">"><mt:var name="label" escape="html"></a></li>\n};
    $bookmark .= "</mt:UserBookmarks></ul></li>\n";
    if ($insert) {
        $insert .= <<'MTML';
        </ul></li>
        <script type="text/javascript" src="<$mt:var name="static_uri"$>plugins/SystemOverview/js/menu.js?v=<mt:var name="mt_version_id" escape="URL">"></script>
MTML
    }
    $insert = $bookmark . $insert;
    $$tmpl =~ s/(<li id="user">)/$insert$1/i;
    my $_51 = $app->version_number < 5.1 ? '' : '_51';
    $insert = <<MTML;
        <link rel="stylesheet" href="<\$mt:var name="static_uri"\$>plugins/SystemOverview/css/style$_51.css?v=<mt:var name="mt_version_id" escape="url">" type="text/css" />
MTML
    $$tmpl =~ s/(<mt:var name="html_head">)/$insert$1/i;
}

sub _list_actions {
    my ( $meth, $component ) = @_;
    my $app = MT->instance;
    my $actions = {
        allow_access_to_mt_cgi => {
            label       => 'Allow access to mt.cgi',
            mode        => 'allow_access_to_mt_cgi',
            return_args => 1,
            order       => 600,
        },
        deny_access_to_mt_cgi => {
            label       => 'Deny access to mt.cgi',
            mode        => 'deny_access_to_mt_cgi',
            return_args => 1,
            order       => 700,
        },
    };
    return $actions;
}

sub _list_can_access_cms {
    my ( $prop, $obj, $app ) = @_;
    my $phrase = 'Disallow';
    if ( $obj->is_superuser || $obj->can_access_cms ) {
        $phrase = 'Allow';
    }
    return MT->translate( $phrase );
}

sub _allow_access_to_mt_cgi {
    my $app = MT::instance();
    if (! $app->user->is_superuser ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $done = 0;
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    for my $id ( @ids ) {
        my $author = MT->model( 'author' )->load( $id );
        if (! $author ) {
            return $app->errtrans( 'Invalid request' );
        }
        if (! $author->is_superuser ) {
            if (! $author->can_access_cms ) {
                $author->can_access_cms( 1 );
                $author->save or die $author->errstr;
                $done ||= 1;
            }
        }
    }
    if ( $done ) {
        $app->add_return_arg( 'allow_access_to_mt_cgi' => 1 );
    } else {
        $app->add_return_arg( 'not_allow_access_to_mt_cgi' => 1 );
    }
    $app->call_return;
}

sub _deny_access_to_mt_cgi {
    my $app = MT::instance();
    if (! $app->user->is_superuser ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $done = 0;
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    for my $id ( @ids ) {
        my $author = MT->model( 'author' )->load( $id );
        if (! $author ) {
            return $app->errtrans( 'Invalid request' );
        }
        if ( $author->is_superuser ) {
            return $app->errtrans( "Can't change permission for system administrator." );
        }
        if ( $author->can_access_cms ) {
            $author->can_access_cms( undef );
            $author->save or die $author->errstr;
            $done ||= 1;
        }
    }
    if ( $done ) {
        $app->add_return_arg( 'deny_access_to_mt_cgi' => 1 );
    } else {
        $app->add_return_arg( 'not_deny_access_to_mt_cgi' => 1 );
    }
    $app->call_return;
}

sub _list_common {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $type = $app->param( '_type' ) ) {
        if ( $type eq 'tag' ) {
            if ( my $filter_key = $app->param( 'filter_key' ) ) {
                if ( ( $filter_key eq 'entry' ) ||
                     ( $filter_key eq 'page' ) ||
                     ( $filter_key eq 'asset' ) ) {
                    $param->{ screen_group } = $filter_key;
                }
            }
        }
    }
}

sub _listing_callback {
    my ( $cb, $obj ) = @_;
    my $app = MT->instance();
    if ( is_cms( $app ) ) {
        my $entry_action;
        if ( $app->mode eq 'itemset_action' ) {
            if ( my $action_name = $app->param( 'action_name' ) ) {
                $entry_action = 1;
            }
        }
        my $selector = $app->param( 'plugin_action_selector' );
        $selector = '' if (! $selector );
        if ( $entry_action || ( $app->mode eq 'rebuild_new_phase' ) ||
           ( $selector && ( $selector eq 'set_draft' ) ) ) {
            require MT::Request;
            my $r = MT::Request->instance;
            my $self = $r->cache( 'post_save_entry_original:' . $obj->id );
            return if $self;
            $r->cache( 'post_save_entry_original:' . $obj->id, 1 );
            my $original = $obj->clone_all;
            if ( $app->mode eq 'rebuild_new_phase' ) {
                $original->status( MT::Entry::HOLD() );
            } elsif ( $selector eq 'set_draft' ) {
                $original->status( MT::Entry::RELEASE() );
            }
            $app->run_callbacks( 'cms_post_save_by_listing.' . $obj->class, $app, $obj, $original );
        }
    }
    return 1;
}

sub _template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    # init side bar
    require MT::Request;
    my $r = MT::Request->instance;
    if (! $app->blog ) {
        my $default_website_url = MT->config( 'DefaultWebSiteURL' );
        if (! $default_website_url ) {
            require MT::Website;
            $default_website_url = MT::Website->load( undef, { limit => 1 } )->site_url;
            __set_default( $app, $default_website_url );
        }
        $param->{ website_url } = $default_website_url;
    }
    if ( my $custom_sidebars_loop = $r->cache( 'custom_sidebars_loop' ) ) {
        $param->{ sidebar_loop } = $custom_sidebars_loop;
        return;
    }
    my @sidebar_loop;
    my $custom_sidebars = MT->registry( 'custom_sidebars' );
    my @sidebars = keys( %$custom_sidebars );
    my %init_sidebars;
    for my $bar ( @sidebars ) {
        $init_sidebars{ $bar } = $custom_sidebars->{ $bar }{ order };
    }
    my @menus;
    foreach my $name ( sort { $init_sidebars{ $a } <=> $init_sidebars{ $b } } keys %init_sidebars ) {
        push ( @menus, $name );
    }
    my $scope_type;
    my $blog_id = $app->param( 'blog_id' );
    if ( defined $blog_id ) {
        if ( ( $blog_id ne '' ) && ( $blog_id eq '0' ) ) {
            $scope_type = 'system';
        } elsif ( $blog_id && ( $app->blog->is_blog ) ) {
            $scope_type = 'blog';
        } elsif ( $blog_id && (! $app->blog->is_blog ) ) {
            $scope_type = 'website';
        }
    }
    if (! $scope_type ) {
        if ( ( $app->mode eq 'dashboard' ) || ( $app->mode eq 'default' ) ) {
            $scope_type = 'user';
        }
    }
    if (! $scope_type ) {
        $scope_type = 'system';
    }
    for my $menu ( @menus ) {
        my $custom_sidebar = $custom_sidebars->{ $menu };
        my $can_view;
        if ( my $permission = $custom_sidebars->{ $menu }{ permission } ) {
            my @perms = split( /,/, $permission );
            for my $perm( @perms ) {
                if ( is_user_can( $app->blog, $app->user, $perm ) ) {
                    $can_view = 1;
                    last;
                }
            }
        } else {
            $can_view = 1;
        }
        my $is_scope;
        if ( my $views = $custom_sidebars->{ $menu }{ view } ) {
            for my $scope( @$views ) {
                if ( $scope_type eq $scope ) {
                    $is_scope = 1;
                    last;
                }
            }
        } else {
            $is_scope = 1;
        }
        if ( $is_scope && $can_view ) {
            my $component = MT->component( $custom_sidebar->{ component } );
            my $custom_sidebar_name = $component->translate( $custom_sidebar->{ name } );
            my $plugin_path = plugin_template_path( $component );
            require File::Spec;
            my $template = File::Spec->catfile( $plugin_path, $custom_sidebar->{ template } );
            push ( @sidebar_loop, { tab_class => $menu, tab_template => $template, tab_name => $custom_sidebar_name, component => $component->id } );
        }
    }
    $r->cache( 'custom_sidebars_loop', \@sidebar_loop );
    $param->{ sidebar_loop } = \@sidebar_loop;
}

sub _edit_author {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $id = $app->param( 'id' );
    my $author = MT->model( 'author' )->load( $id ) if $id;
    my $loaded_permissions = $param->{ loaded_permissions };
    my @new_perms;
    for my $perm ( @$loaded_permissions ) {
        if ( $perm->{ id } eq 'can_access_cms' ) {
            if ( $id ) {
                if ( $author->is_superuser ) {
                    $perm->{ can_do } = 1;
                } else {
                    $perm->{ can_do } = $author->can_access_cms;
                }
            } else {
                $perm->{ can_do } = 1;
            }
        }
        push ( @new_perms, $perm );
    }
    $param->{ loaded_permissions } = \@new_perms;
}

sub _pre_run {
    my($cb, $app) = @_;
    if ( ! $app->param( '__mode' ) || $app->param( '__mode' ) ne 'logout' ) {
        if ( my $user = $app->user ) {
            if (! $user->is_superuser && ! $user->can_access_cms ) {
                $app->user( undef );
                if ( ( $app->{ query } ) && ( $app->{ query }{ param } ) ) {
                    $app->{ query }{ param }{ __mode } = '';
                }
                my $redirect_url = $app->base . $app->uri( mode => 'logout' );
                return $app->redirect( $redirect_url );
                # return $app;
            }
        }
    }
    __AltL10N($app);
    if ( $app->param( '__mode' ) && ( $app->param( '__mode' ) eq 'save_cfg_system_general' ) ) {
        if ( my $default_website_url = $app->param( 'default_website_url' ) ) {
            __set_default( $app, $default_website_url );
        }
        __minifier($app);
    }
    my $plugin = MT->component( 'PowerCMS' );
    require File::Spec;
    MT->config( 'AltTemplatePath', File::Spec->catdir( $plugin->path, 'alt-tmpl' ) );
    if ( $app->mode ne 'dashboard' ) {
        return;
    }
    my $menus = MT->registry( 'applications', 'cms', 'menus' );
    for my $menu ( values( %$menus ) ) {
        if ( $menu->{ view } ) {
            if ( ( ref ( $menu->{ view } )
                && grep( $_ eq 'system', @{ $menu->{ view } } ) ) ) {
                if ( ref ( $menu->{ view } ) ) {
                    my @scope = @{ $menu->{ view } };
                    push ( @scope, 'user' );
                    $menu->{ view } = \@scope;
                    $menu->{ args }{ blog_id } = 0;
                }
            } else {
                if ( $menu->{ view } eq 'system' ) {
                    $menu->{ view } = [ 'system', 'user' ];
                    $menu->{ args }{ blog_id } = 0;
                }
            }
        }
    }
    unless ( MT->config( 'RemovableThisIsYouWidget' ) ) {
        return 1;
    }
    my $core = MT->component( 'core' );
    my $r;
    eval { $r = $core->registry( 'applications', 'cms', 'widgets' ) };
    if (! $@ ){
        $r->{ this_is_you } = { label => 'This is You',
                                template => 'widget/this_is_you.tmpl',
                                handler => 'MT::CMS::Dashboard::this_is_you_widget',
                                set => 'sidebar',
                                singular => 1,
                                view => 'user', };
    }
    return 1;
}

sub __AltL10N {
    my $app = shift;
    my $plugin = MT->component( 'PowerCMS' );
    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my $lh = MT->language_handle;
    my $language = ref $lh;
    $language =~ s/^.+:://;
    require File::Spec;
    my $l10n;
    if ( my $blog = $app->blog ) {
        $l10n = File::Spec->catfile( $plugin->path, 'L10N', $blog->id, "$language.pm" );
        if (! $fmgr->exists( $l10n ) ) {
            $l10n = undef;
        }
    }
    if (! $l10n ) {
        $l10n = File::Spec->catfile( $plugin->path, 'L10N', "$language.pm" );
    }
    if ( $fmgr->exists( $l10n ) ) {
        my $data = $fmgr->get_data( $l10n );
        eval( $data );
    }
    return 1;
}

sub __minifier {
    # TODO: Display errors.
    my $app = shift;
    if ( $ENV{SERVER_SOFTWARE} =~ /Microsoft-IIS/ ) {
         return 1;
    }
    unless ( $app->user->is_superuser ) {
        $app->return_to_dashboard( permission => 1 );
    }

    my $use_minifier = scalar $app->param('use_minifier') ? 1 : 0;
    my $static_file_path = chomp_dir( $app->static_file_path );
    my $htaccess = File::Spec->catfile($static_file_path, '.htaccess');
    unless ( -w $static_file_path ) {
        #if ($use_minifier) {
        # Error.
        #} elsif (-f $htaccess) {
        # Error.
        #}
        return 1;
    }
    require File::Spec;
    my $dir = File::Spec->catdir( $static_file_path, 'minify_2' );
    unless ( -d $dir ) {
        #if ($use_minifier) {
        # Error.
        #}
        return 1;
    }
    my $tmpl = <<'MTML';
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteRule ^(.+\.(cs|j)s)$ <$MTStaticWebPath abs_addslash="1"$>minify_2/min/index.php?f=<$MTStaticWebPath abs_addslash="1" regex_replace="/^\/+/",""$>$1 [NC,L,NE]
</IfModule>
MTML
    my $cfg = read_from_file($htaccess);
    my $new_cfg = 0; # TODO: ugly
    unless ($cfg) {
        unless ($use_minifier) {
            return 1;
        }
        $cfg = build_tmpl($app, $tmpl);
        $new_cfg++;
    }
    unless ($cfg) {
        #if ($use_minifier) {
        # Error.
        #}
        return 1;
    }
    unless ($cfg =~ s{
        ^ (?= \s* (?i:RewriteRule) \s+ \S+ \s+ \S+/minify_2/min/\S )
    }{ $use_minifier ? '' : '#' }emx || $use_minifier) {
        return 1;
    }
    if ($use_minifier && !($cfg =~ s{
            ^ \s* # (?= \s* (?i:RewriteRule) \s+ \S+ \s+ \S+/minify_2/min/\S )
    }{}mx)) {
        $cfg .= build_tmpl($app, $tmpl) unless $new_cfg;
    }
    unless (write2file($htaccess, $cfg)) {
    # Error.
    }

    $dir = File::Spec->catdir($dir, 'min');
    unless (-w $dir) {
        return 1;
    }
    my $config_php = File::Spec->catfile($dir, 'config.php');
    unless (-w $config_php) {
        return 1;
    }
    $cfg = read_from_file($config_php);
    if ($cfg =~ m{^\s*\$min_cachePath\s*=\s*["']}m) {
        return 1;
    }
    my $temp_dir = $app->config('TempDir');
    if ($cfg =~ s{^(//(\$min_cachePath\s*=\s*')/tmp(';))$}{$1\n$2$temp_dir$3}m) {
        unless (write2file($config_php, $cfg)) {
        # Error.
        }
    }
    return 1;
}

sub __set_default {
    my ( $app, $default_website_url ) = @_;
    my $cfg = $app->config;
    $app->config( 'DefaultWebSiteURL', $default_website_url || undef, 1 );
    $cfg->save_config();
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;
    my $count = MT->model( 'powercmsconfig' )->count();
    if ( $count >= 2 ) {
        my @powercmsconfigs = MT->model( 'powercmsconfig' )->load( undef,
                                                                   { offset => 1,
                                                                     'sort' => 'id',
                                                                     direction => 'ascend',
                                                                   },
                                                                 );
        for my $powercmsconfig ( @powercmsconfigs ) {
            next unless $powercmsconfig->restored;
            my $data = $powercmsconfig->data;
            if ( ! ( ref $data ) && $data =~ /^HASH/ ) {
                $powercmsconfig->remove;
            }
        }
    }
}

sub _newuserprovisioning {
    my ( $cb, $author ) = @_;
    $author->can_access_cms( 1 );
    $author->save or die $author->errstr;
    return 1;
}

1;
