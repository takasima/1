package PowerTheme::Plugin;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( save_asset current_user current_ts site_path file_label
                       is_ua_keitai
                     );
use PowerTheme::Util;
use PowerTheme::Import;
use MT::Util;

sub _cb_post_apply_theme_remove_unedition_templates {
    my ( $cb, $theme, $blog ) = @_;
    my $plugin = MT->component( 'PowerTheme' );
    my $blog_id = $blog->id;
    unless ( MT->component( 'PowerSearch' ) ) {
#        if ( my $entry_draft = MT::Template->load( { identifier => 'entry_draft', blog_id => $blog_id } ) ) {
#            $entry_draft->remove or die $entry_draft->errstr;
#        }
#        if ( my $page_draft = MT::Template->load( { identifier => 'page_draft', blog_id => $blog_id } ) ) {
#            $page_draft->remove or die $page_draft->errstr;
#        }
#        if ( my $estraier_result = MT::Template->load( { identifier => 'estraier_result', blog_id => $blog_id } ) ) {
#            $estraier_result->remove or die $estraier_result->errstr;
#        }
        my @estraier = MT::Template->load( { identifier => { like => 'estraier_%' }, blog_id => $blog_id } );
        for my $estraier_tmpl ( @estraier ) {
            $estraier_tmpl->remove or die $estraier_tmpl->errstr;
        }
    }
    unless ( MT->component( 'Members' ) ) {
        my @mobiles = MT::Template->load( { identifier => { like => 'mobile_%' }, blog_id => $blog_id } );
        for my $mobile_tmpl ( @mobiles ) {
            $mobile_tmpl->remove or die $mobile_tmpl->errstr;
        }
        my @members = MT::Template->load( { identifier => { like => 'members_%' }, blog_id => $blog_id } );
        for my $members_tmpl ( @members ) {
            $members_tmpl->remove or die $members_tmpl->errstr;
        }
        my $signin_std_path = File::Spec->catfile( $plugin->path, 'templates', 'signin_std.mtml' );
        if ( -f $signin_std_path ) {
            my $fmgr = MT::FileMgr->new( 'Local' );
            if ( my $text = $fmgr->get_data( $signin_std_path ) ) {
                my $tmpl = MT::Template->load( { identifier => 'signin', blog_id => $blog_id } );
                if ( $tmpl ) {
                    $tmpl->text( $text );
                    $tmpl->save or die $tmpl->errstr;
                }
            }
        }
    }
}

sub _cb_post_apply_theme_blog {
    my ( $cb, $theme, $blog ) = @_;
    return unless $blog->is_blog;
    my $powercms_theme_ids = PowerTheme::Util::powercms_blog_theme_ids();
    return unless $powercms_theme_ids;
    return unless grep { $_ eq $blog->theme_id } @$powercms_theme_ids;
    my $app = MT->instance();
    return if $app->mode eq 'refresh_all_templates';
    return if $app->mode eq 'apply_theme';
    my $blog_settings = PowerTheme::Util::blog_settings();
    for my $column ( keys %$blog_settings ) {
        if ( $blog->has_column( $column ) ) {
            my $value = $blog_settings->{ $column };
            $blog->$column( $value );
        }
    }
    $blog->save or die $blog->errstr;
    my $user = current_user( $app );
    my @saved_entrygroups;
    if ( $blog->theme_id eq 'power_cms_blog_case_study' ) {
        my $blog_entrygroups = PowerTheme::Util::blog_entrygroups();
        my $entrygroups = $blog_entrygroups->{ 'examples' };
        if ( $entrygroups ) {
            for my $entrygroup ( @$entrygroups ) {
                my $group = MT->model( 'entrygroup' )->new;
                $group->blog_id( $blog->id );
                $group->author_id( $user->id );
                for my $column ( keys %$entrygroup ) {
                    next if $column eq 'entries';
                    if ( $group->has_column( $column ) ) {
                        $group->$column( $entrygroup->{ $column } );
                    }
                }
                $group->save or die $group->errstr;
                push( @saved_entrygroups, $entrygroup );
            }
        }
    }
    PowerTheme::Import::_import_object( $app, $blog, $blog->theme_id, 'entry' );
    PowerTheme::Import::_import_object( $app, $blog, $blog->theme_id, 'page' );
    if ( @saved_entrygroups ) {
        for my $entrygroup ( @saved_entrygroups ) {
            my $entries = $entrygroup->{ 'entries' };
            my $i = 0;
            for my $title ( @$entries ) {
                my $entry = MT->model( 'entry' )->load( { title => $title,
                                                          blog_id => $blog->id,
                                                        },
                                                      );
                if ( $entry ) {
                    my $group = MT->model( 'entrygroup' )->load( { name => $entrygroup->{ name },
                                                                   blog_id => $blog->id,
                                                                 }
                                                               );
                    if ( $group ) {
                        my $grouporder = MT->model( 'grouporder' )->new;
                        $grouporder->group_id( $group->id );
                        $grouporder->object_id( $entry->id );
                        $grouporder->order( 500 + $i );
                        $grouporder->save or die $grouporder->errstr;
                    }
                }
                $i++;
            }
        }
    }
}

sub _cb_post_apply_theme_website {
    my ( $cb, $theme, $website ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $powercms_installed = $r->cache( 'powercms_installed' );
    if ( $powercms_installed ) {
        return;
    }
    return if $website->is_blog;
    my $powercms_theme_ids = PowerTheme::Util::powercms_website_theme_ids();
    return unless $powercms_theme_ids;
    return unless grep { $_ eq $website->theme_id } @$powercms_theme_ids;
    my $app = MT->instance();
    my $website_path = site_path( $website );
    if ( ( ref $app ) eq 'MT::App::Upgrader' && ! $website_path ) {
        $website_path = $app->param( 'website_path' );
    }
    if ( $website_path ) {
        return if $app->mode eq 'refresh_all_templates';
        return if $app->mode eq 'apply_theme';

        my $plugin = MT->component( 'PowerTheme' );
        my $user = current_user( $app );

        my $website_settings = PowerTheme::Util::website_settings();
        for my $column ( keys %$website_settings ) {
            if ( $website->has_column( $column ) ) {
                my $value = $website_settings->{ $column };
                $website->$column( $value );
            }
        }
        $website->save or die $website->errstr;

        my $website_plugin_settings = PowerTheme::Util::website_plugin_settings();
        for my $plugin_id ( keys %$website_plugin_settings ) {
            my $website_plugin = MT->component( $plugin_id );
            my $scope = 'blog:' . $website->id;
            my $settings = $website_plugin_settings->{ $plugin_id };
            for my $key ( keys %$settings ) {
                my $value = $settings->{ $key };
                $website_plugin->set_config_value( $key, $value, $scope );
            }
        }

        my $fmgr = $website->file_mgr;

        my $website_campaigns = PowerTheme::Util::website_campaigns();
        for my $website_campaign ( @$website_campaigns ) {
            my $campaign = MT->model( 'campaign' )->new;
            $campaign->blog_id( $website->id );
            $campaign->author_id( $user->id );
            $campaign->period_on( current_ts( $website ) );
            for my $column ( keys %$website_campaign ) {
                if ( $column eq 'path' ) {
                    my $path = $website_campaign->{ path };
                    my $file_path = File::Spec->catfile( $website_path, $path );
                    my $asset;
                    if ( $fmgr->exists( $file_path ) ) {
                        my $basename = file_label( $file_path );
                        my %params = ( file => $file_path,
                                       author => $user,
                                       label => $basename,
                                     );
                        $asset = save_asset( MT->instance(), $website, \%params );
                        if ( $asset ) {
                            $campaign->image_id( $asset->id );
                        }
                    }
                } elsif ( $campaign->has_column( $column ) ) {
                    $campaign->$column( $website_campaign->{ $column } );
                }
            }
            $campaign->save or die $campaign->errstr;
            if ( my $tags = $website_campaign->{ 'tags' } ) {
                my @tag_names = split( /\s*,\s*/, $tags );
                $campaign->add_tags( @tag_names );
                $campaign->save or die $campaign->errstr;
            }
        }

        my $website_campaign_groups = PowerTheme::Util::website_campaign_groups();
        for my $website_campaign_group ( @$website_campaign_groups ) {
            my $campaigngroup = MT->model( 'campaigngroup' )->new;
            $campaigngroup->blog_id( $website->id );
            $campaigngroup->author_id( $user->id );
            for my $column ( keys %$website_campaign_group ) {
                next if $column eq 'campaigns';
                if ( $campaigngroup->has_column( $column ) ) {
                    $campaigngroup->$column( $website_campaign_group->{ $column } );
                }
            }
            $campaigngroup->save or die $campaigngroup->errstr;
            my $titles = $website_campaign_group->{ 'campaigns' };
            my $i = 0;
            for my $title ( @$titles ) {
                my $campaign = MT->model( 'campaign' )->load( { title => $title,
                                                                blog_id => $website->id,
                                                              }
                                                           );
                if ( $campaign ) {
                    my $campaignorder = MT->model( 'campaignorder' )->new;
                    $campaignorder->campaign_id( $campaign->id );
                    $campaignorder->group_id( $campaigngroup->id );
                    $campaignorder->order( 500 + $i );
                    $campaignorder->save or die $campaignorder->errstr;
                }
                $i++;
            }
        }

        my $website_contactforms = PowerTheme::Util::website_contactforms();
        for my $website_contactform ( @$website_contactforms ) {
            my $contactform = MT->model( 'contactform' )->get_by_key( { name => $website_contactform->{ name },
                                                                        type => $website_contactform->{ type },
                                                                        blog_id => 0,
                                                                      }
                                                                    );
            $contactform->blog_id( 0 );
            $contactform->author_id( $user->id );
            for my $column ( keys %$website_contactform ) {
                next if $column eq 'name';
                next if $column eq 'type';
                if ( $contactform->has_column( $column ) ) {
                    $contactform->$column( $website_contactform->{ $column } );
                }
            }
            $contactform->save or die $contactform->errstr;
        }


        my $website_contactformgroups = PowerTheme::Util::website_contactformgroups();
        for my $website_contactformgroup ( @$website_contactformgroups ) {
            my $contactformgroup = MT->model( 'contactformgroup' )->new;
            $contactformgroup->blog_id( $website->id );
            $contactformgroup->author_id( $user->id );
            $contactformgroup->modified_on( current_ts( $website ) );
            $contactformgroup->created_on( current_ts( $website ) );
    #        $contactformgroup->period_on( current_ts( $website ) );
            $contactformgroup->publishing_on( current_ts( $website ) );
            my $terms = $website_contactformgroup->{ cms_tmpl };
            $terms->{ blog_id } = $website->id;
            my $template = MT->model( 'template' )->load( $terms );
            if ( $template ) {
                $contactformgroup->cms_tmpl( $template->id );
            }
            for my $column ( keys %$website_contactformgroup ) {
                next if $column eq 'contactforms';
                next if $column eq 'cms_tmpl';
                if ( $contactformgroup->has_column( $column ) ) {
                    $contactformgroup->$column( $website_contactformgroup->{ $column } );
                }
            }
            $contactformgroup->save or die $contactformgroup->errstr;
            my $contactforms = $website_contactformgroup->{ 'contactforms' };
            my $i = 0;
            for my $name ( @$contactforms ) {
                my $contactform = MT->model( 'contactform' )->load( { name => $name,
                                                                      blog_id => 0,
                                                                    }
                                                                  );
                if ( $contactform ) {
                    my $contactformorder = MT->model( 'contactformorder' )->new;
                    $contactformorder->contactform_id( $contactform->id );
                    $contactformorder->group_id( $contactformgroup->id );
                    $contactformorder->order( 500 + $i );
                    $contactformorder->save or die $contactformorder->errstr;
                }
                $i++;
            }
        }

        my $website_customobjects = PowerTheme::Util::website_customobjects();
        for my $website_customobject ( @$website_customobjects ) {
            my $customobject = MT->model( 'customobject' )->new;
            $customobject->blog_id( $website->id );
            $customobject->author_id( $user->id );
            $customobject->period_on( current_ts( $website ) );
            my $folder = $website_customobject->{ 'folder' };
            for my $column ( keys %$website_customobject ) {
                if ( $column eq 'folder' ) {
                    my $label = $website_customobject->{ folder };
                    my $folder = MT->model( 'folder' )->load( { label => $label,
                                                                blog_id => $website->id,
                                                              }
                                                            );
                    if ( $folder ) {
                        $customobject->category_id( $folder->id );
                    }
                } elsif ( $customobject->has_column( $column ) ) {
                    $customobject->$column( $website_customobject->{ $column } );
                }
            }
            $customobject->save or die $customobject->errstr;
        }

        my $website_customobject_groups = PowerTheme::Util::website_customobject_groups();
        for my $website_customobject_group ( @$website_customobject_groups ) {
            my $customobjectgroup = MT->model( 'customobjectgroup' )->new;
            $customobjectgroup->blog_id( $website->id );
            $customobjectgroup->author_id( $user->id );
            for my $column ( keys %$website_customobject_group ) {
                next if $column eq 'customobjects';
                if ( $customobjectgroup->has_column( $column ) ) {
                    $customobjectgroup->$column( $website_customobject_group->{ $column } );
                }
            }
            $customobjectgroup->save or die $customobjectgroup->errstr;
            my $names = $website_customobject_group->{ 'customobjects' };
            my $i = 0;
            for my $name ( @$names ) {
                my $customobject = MT->model( 'customobject' )->load( { name => $name,
                                                                        blog_id => $website->id,
                                                                      }
                                                                    );
                if ( $customobject ) {
                    my $customobjectorder = MT->model( 'customobjectorder' )->new;
                    $customobjectorder->customobject_id( $customobject->id );
                    $customobjectorder->group_id( $customobjectgroup->id );
                    $customobjectorder->order( 500 + $i );
                    $customobjectorder->save or die $customobjectorder->errstr;
                }
                $i++;
            }
        }

        PowerTheme::Import::_import_object( $app, $website, $website->theme_id, 'page' );

        push ( my @scope_blog_ids, map { $_->id } ( $website, @{ $website->blogs } ) );
        my $website_objjectgroups = PowerTheme::Util::website_objjectgroups();
        for my $website_objjectgroup ( @$website_objjectgroups ) {
            my $objectgroup = MT->model( 'objectgroup' )->new;
            $objectgroup->blog_id( $website->id );
            $objectgroup->author_id( $user->id );
            $objectgroup->modified_on( current_ts( $website ) );
            $objectgroup->created_on( current_ts( $website ) );
            for my $column ( keys %$website_objjectgroup ) {
                next if $column eq 'items';
                if ( $objectgroup->has_column( $column ) ) {
                    $objectgroup->$column( $website_objjectgroup->{ $column } );
                }
            }
            $objectgroup->save or die $objectgroup->errstr;
            my $items = $website_objjectgroup->{ 'items' };
            my $i = 0;
            for my $item ( @$items ) {
                my $class = $item->{ class };
                my $object;
                if ( $class eq 'website' ) {
                    $object = $website;
                } else {
                    my $key = $item->{ key };
                    my $value = $item->{ value };
                    unless ( $key || $value ) {
                        next;
                    }
                    $object = MT->model( $class )->load( { $key => $value,
                                                           ( $class eq 'blog'
                                                                ? ( parent_id => $website->id )
                                                                : ( blog_id => \@scope_blog_ids )
                                                           ),
                                                         }
                                                       );
                }
                if ( $object ) {
                    my $objectorder = MT->model( 'objectorder' )->new;
                    $objectorder->class( $object->class );
                    $objectorder->object_ds( $object->datasource );
                    $objectorder->object_id( $object->id );
                    $objectorder->objectgroup_id( $objectgroup->id );
                    $objectorder->number( 500 + $i );
                    $objectorder->save or die $objectorder->errstr;
                }
                $i++;
            }
        }
        PowerTheme::Util::save_blog_assets( $website );

        $r = MT::Request->instance;
        unless ( $r->cache( 'powercms_installed' ) ) {
            $r->cache( 'powercms_installed', '1' );
        }
        return 1;
    }
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin_powercms = MT->component( 'PowerTheme' );
    my $type = $param->{ type };
    my $ident = $param->{ identifier } or return;
    return unless $type;
    return unless $app->blog;
    return unless $ident =~ m/(mail|notify|wf_)/;
    my $body_node = $tmpl->getElementById( 'template-body' );
    return unless $body_node;
    my $inner = <<'MTML';
<input
    type="text" name="subject" id="subject"
    value="<$mt:var name="subject" escape="html"$>"
    maxlength="500" mt:watch-change="1" />
MTML
    my $subject_node = $tmpl->createElement( 'app:setting', {
        id => 'subject',
        label => $plugin_powercms->translate( 'Subject' ),
        label_class => 'top-level',
    } );
    $subject_node->innerHTML( $inner );
    $tmpl->insertBefore( $subject_node, $body_node );
}

sub _check_theme {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerTheme' );
    my $search = quotemeta( q{<mt:include name="include/header.tmpl">} );
    my $plugin_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'PowerTheme_header.tmpl' );
    my $insert = qq{<mt:include name="$plugin_tmpl" component="PowerTheme">};
    $$tmpl =~ s/($search)/$insert$1/;
}

sub _cb_comments_pre_run {
    my $app = MT->instance;
    if ( is_ua_keitai( $app ) ) {
        if ( my $blog = $app->blog ) { # forrowing from MT::App::Comments
            my $path = $blog->site_path;
            $path .= '/' unless $path =~ m!/$!;
            my $site_path_sha1 = MT::Util::perl_sha1_digest_hex($path);
            $app->param( 'armor', $site_path_sha1 );
        }
    }
}

1;

__END__
