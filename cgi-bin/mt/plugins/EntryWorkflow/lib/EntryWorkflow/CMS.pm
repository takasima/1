package EntryWorkflow::CMS;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( send_mail build_tmpl site_path write2file current_ts is_user_can
                       current_user file_extension file_basename
                     );
use MT::Util qw( decode_url offset_time_list encode_html );
use EntryWorkflow::Util;

sub _mode_wf_redirect {
    my $app = MT->instance();
    return $app->redirect( decode_url( $app->param( 'return_url' ) ) );
}

sub _mode_preview2publish {
    my $app = shift;
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $plugin = MT->component( 'EntryWorkflow' );
    my $id = $app->param( 'id' );
    my $entry = MT::Entry->load( { id => $id,
                                   class => [ 'entry', 'page' ],
                                 }
                               );
    unless ( defined $entry ) {
        return $app->trans_error( 'Load failed: [_1]', "ID:$id" );
    }
    my $class = $entry->class;
    if ( $class eq 'page' ) {
        $entry = MT->model( 'page' )->load( { id => $id } );
    }
    my $original = $entry->clone_all();
    my $blog = $entry->blog;
    # Check Permission.
    unless ( is_user_can( $blog, $app->user, 'rebuild' ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    unless ( is_user_can( $blog, $app->user, 'publish_post' ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    if ( $entry->status == MT::Entry::HOLD() || $entry->status == MT::Entry::REVIEW() ) {
        $entry->author_id( $app->user->id );
    }
    $entry->status( MT::Entry::RELEASE() );
    $entry->save or die $entry->errstr;

    if ( my $multiblog = MT->component( 'MultiBlog' ) ) {
        $multiblog->runner( 'post_entry_save', undef, $app, $entry );
    }

    if ( $class eq 'entry' ) {
        _rebuild_entry( $entry, 1 );
    } elsif ( $class eq 'page' ) {
        _rebuild_entry( $entry, 0 );
    }
    EntryWorkflow::Plugin::_cb_post_save_entry( undef, $app, $entry, $original );
    MT->run_callbacks( 'cms_workflow_published.' . $entry->class, $app, $entry );
    my $return_url = $app->base . $app->uri( mode => 'view', 
                                             args => { _type => $class,
                                                       id => $id,
                                                       blog_id => $entry->blog_id,
                                                       saved_changes => 1,
                                                     },
                                           );
    return $app->redirect( $return_url );
}

sub _mode_sendback {
    my $app = shift;
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $plugin = MT->component( 'EntryWorkflow' );
    my $id = $app->param( 'id' );
    my $revision_id = $app->param( 'revision_id' );
    if ( $revision_id && $id < 0 ) {
        $id *= -1;
    }
    my $user = current_user( $app );
    my $has_permission = 0;
    my ( $blog, $entry, $revision );
    if ( $revision_id ) { # TODO: this flow for PowerRevision...
        $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
        unless ( defined $revision ) {
            return $app->trans_error( 'Load failed: [_1]', "ID:$revision_id" );
        }
        $has_permission = EntryWorkflow::Util::can_edit_revision( $revision, $user );
        $blog = $revision->blog;
        $entry = $revision->original;
    } else {
        $entry = MT::Entry->load( { id => $id,
                                    class => [ 'entry', 'page' ],
                                  }
                                );
        unless ( defined $entry ) {
            return $app->trans_error( 'Load failed: [_1]', "ID:$id" );
        }
        $has_permission = EntryWorkflow::Util::can_edit_entry( $entry, $user );
        $blog = $entry->blog;
    }
    unless ( $has_permission ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $change_author_id = $app->param( 'change_author_id' );
    unless ( $change_author_id =~ /^[0-9]{1,}$/ ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $change_author = MT->model( 'author' )->load( { id => $change_author_id,
                                                       status => MT::Author::ACTIVE(),
                                                     }
                                                   );
    unless ( $change_author ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $message = $app->param( 'entry-workflow-message' );
    my $is_approval = $app->param( 'wf_status_approval' );
    my $class;
    if( $revision_id ){
        $class = $revision->object_class;
    }else{
        $class = $entry->class;
    }
    if ( $class eq 'page' ) {
        $entry = MT->model( 'page' )->load( { id => $id } );
    }
    my ( $original_author, $title ); # for workflow log
    if ( $revision_id ) {
        unless ( $revision ) {
            $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
        }
        $original_author = $revision->author;
        $revision->status( $is_approval ? MT::Entry::REVIEW() : MT::Entry::HOLD() );
        $revision->author_id( $change_author_id );
        $revision->save or die $revision->errstr;
        $title = $revision->object_name;
    } else {
        $original_author = $entry->author;
        $entry->status( $is_approval ? MT::Entry::REVIEW() : MT::Entry::HOLD() );
        $entry->author_id( $change_author_id );
        $entry->save or die $entry->errstr;
        $title = $entry->title;
    }
    my $options;
    $options->{ message } = $message;
    $options->{ is_approval } = $is_approval;
    $options->{ revision } = $revision;
    $options->{ change_author } = $change_author;
    my ( $subject, $body ) = EntryWorkflow::Util::build_mail( $app, $entry, $user, $options );
    my $from = MT->config->EmailAddressMain || $user->email;
    my $to = $change_author->email;
    my $res = send_mail( $from, $to, $subject, $body );
    EntryWorkflow::Util::workflow_log( $class, $title, $user, $original_author, $change_author );
    my $return_url;
    if ( $revision_id ) {
        if ( is_user_can( $blog, $user, 'publish_post' ) ) {
            $return_url = $app->base . $app->uri( mode => 'edit_revision', 
                                                  args => { _type => $class,
                                                            blog_id => $revision->blog_id,
                                                            saved_changes => 1,
                                                            revision_id => $revision_id,
                                                            entry_id => $id,
                                                          },
                                                );
        } else {
            $return_url = $app->base . $app->uri( mode => 'list', 
                                                  args => { _type => 'powerrevision',
                                                            blog_id => $entry->blog_id,
                                                            filter => 'object_class',
                                                            filter_val => $class,
                                                            saved => 1,
                                                          },
                                                );
        }
    } elsif ( EntryWorkflow::Util::can_edit_entry( $entry, $user ) ) {
        $return_url = $app->base . $app->uri( mode => 'view', 
                                              args => { _type => $class,
                                                        id => $id,
                                                        blog_id => $entry->blog_id,
                                                        saved_changes => 1,
                                                      },
                                            );
    }
    unless ( $return_url ) {
        $return_url = $app->base . $app->uri( mode => 'list',
                                              args => { blog_id => $entry->blog_id,
                                                        _type => $class,
                                                        saved => 1,
                                                        no_rebuild => 1,
                                                      },
                                            );
    }
    $app->run_callbacks( ( ref $app ) . '::entryworkflow_post_sendback', $app, $entry, \$return_url, $change_author, $revision );
    return $app->redirect( $return_url );
}

sub _mode_sendback_dialog {
    my $app = shift;
    # $app->validate_magic or
    #     return $app->trans_error( 'Permission denied.' );
    my $plugin = MT->component( 'EntryWorkflow' );
    my $id = $app->param( 'id' );
    my $blog = $app->blog;
    my $blog_id = $blog->id;
    my $revision_id = $app->param( 'revision_id' );
    my $user = current_user( $app );
    my ( $owner, $owner_id, $class, $creater_id );
    my $entry;
    if (! $revision_id ) {
        $entry = MT::Entry->load( { id => $id } );
        unless ( defined $entry ) {
            return $app->trans_error( 'Load failed: [_1]', "ID:$id" );
        }
        unless ( EntryWorkflow::Util::can_edit_entry( $entry, $user ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        $class = $entry->class;
        if ( $class eq 'page' ) {
            $entry = MT->model( 'page' )->load( { id => $id } );
        }
        if ( $entry->has_column( 'owner_id' ) ) {
            $owner_id = $entry->owner_id;
        }
        unless ( $owner_id ) {
            $owner_id = $entry->author_id;
        }
        if ( $owner_id != $app->user->id ) {
            $owner = MT->model( 'author' )->load( { id => $owner_id } );
        }
        $class = $entry->class;
        $creater_id = $entry->creator_id;
        $revision_id = '';
    } else {
        my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
        unless ( defined $revision ) {
            return $app->trans_error( 'Load failed: [_1]', "ID:$revision_id" );
        }
        unless ( EntryWorkflow::Util::can_edit_entry( $revision, $user ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        $owner_id = $revision->owner_id;
        unless ( $owner_id ) {
            $owner_id = $revision->author_id;
        }
        if ( $owner_id != $app->user->id ) {
            $owner = MT->model( 'author' )->load( { id => $owner_id } );
        }
        $revision_id = $revision->id;
        $class = $revision->object_class;
        $entry = $revision->original;
    }
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my $tmpl = 'wf_sendbackdialog.tmpl';
    my $wf_params = EntryWorkflow::Util::get_wf_params( $blog, $class, $app->user ); 
    my %param;
    $param{ wf_administer } = $wf_params->{ wf_administer };
    $param{ wf_can_publish } = $wf_params->{ wf_can_publish };
    $param{ wf_publisher } = $wf_params->{ wf_publisher };
    $param{ wf_approver } = $wf_params->{ wf_approver };
    $param{ wf_creator } = $wf_params->{ wf_creator };
    $param{ wf_not_edit_all_posts } = $wf_params->{ wf_not_edit_all_posts };
    $param{ powercms_installed } = $wf_params->{ powercms_installed };
    my ( $creator_loop, $approver_loop, $publisher_loop, $administer_loop )
        = EntryWorkflow::Util::get_loops( $blog, $class, $app->user, ( ! $revision_id ? $entry : () ) );
    $param{ approver_loop } = $approver_loop;
    $param{ creator_loop } = $creator_loop;
    $param{ publisher_loop } = $publisher_loop;
    $param{ administer_loop } = $administer_loop;
    $param{ entry_id } = $id;
    $param{ blog_id } = $blog_id;
    $param{ object_type } = $class;
    $param{ revision_id } = $revision_id;
    return $app->build_page( $tmpl, \%param );
}

sub _mode_preview {
    my $app = shift;
    my $plugin = MT->component( 'EntryWorkflow' );
    my $id = $app->param( 'id' );
    my $entry = MT::Entry->load( { id => $id } );
    unless ( defined $entry ) {
        return $app->trans_error( 'Load failed: [_1]', "ID:$id" );
    }
    my $class = $entry->class;
    if ( $class eq 'page' ) {
        $entry = MT->model( 'page' )->load( { id => $id } );
    }
    my $blog = $entry->blog;
    my $user = current_user( $app );
    unless ( EntryWorkflow::Util::can_edit_entry( $entry, $user ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $preview_basename = $app->preview_object_basename;
    my $permalink = $entry->permalink;
#    $permalink =~ s!^(.*/).*$!$1$preview_basename$permalink_file_extension!;
    my $permalink_file_extension = file_extension( file_basename( $permalink ) );
    $permalink =~ s!^(.*/).*$!$1$preview_basename!;
    if ( $permalink_file_extension ) {
        $permalink .= '.' . $permalink_file_extension;
    }
    my $site_path = site_path( $blog );
    my $file = $entry->archive_file();
    $file = File::Spec->catfile( $site_path, $file );
    my $at;
    if ( $class eq 'entry' ) {
         $at = 'Individual';
    } elsif ( $class =~ 'page' ) {
         $at = 'Page';
    }
    my $template = MT->model( 'template' )->load( { blog_id => $blog->id },
                                                  { 'join' => [ 'MT::TemplateMap',
                                                                'template_id',
                                                                { blog_id => $blog->id,
                                                                  archive_type => $at,
                                                                  is_preferred => 1,
                                                                }, { 
                                                                  unique => 1,
                                                                },
                                                              ],
                                                  },
                                               );
    unless ( defined $template ) {
        $app->trans_error( 'Can\'t load template.' );
    }
    $app->run_callbacks( ( ref $app ) . '::powerpreview_post_load_template', $app, \$template, $entry );
    my $tmpl_class = $class . '_template';
    my %args = ( blog => $blog,
                 entry => $entry,
               );
#     my %params = ( $tmpl_class => 1,
#                    'preview_template' => 1,
#                    'power_preview' => 1,
#                  );
    my %params;
    if ( my $archiver = MT->publisher->archiver( $at ) ) {
        if ( my $tmpl_param = $archiver->template_params ) {
            %params = %$tmpl_param;
        }
    }
    $params{ $tmpl_class } = 1;
    $params{ preview_template } = 1;
    $params{ power_preview } = 1;
    my $html = build_tmpl( $app, $template, \%args, \%params );
#     my $outfile_extension = file_extension( file_basename( $file ) ) || '';
#     $file =~ s!^(.*/).*$!$1$preview_basename$outfile_extension!;
#     if ( $file =~ m/\\/ ) {
#         $file =~ s!^(.*\\).*$!$1$preview_basename$outfile_extension!;
#     }
    my $outfile_extension = file_extension( file_basename( $file ) );
    $file =~ s!^(.*/).*$!$1$preview_basename!;
    if ( $file =~ m/\\/ ) {
        $file =~ s!^(.*\\).*$!$1$preview_basename!;
    }
    if ( $outfile_extension ) {
        $file .= '.' . $outfile_extension;
    }
    $app->run_callbacks( ( ref $app ) . '::powerpreview_pre_preview', $app, $entry, \$html, \$file, $preview_basename );
    require File::Basename;
    my $dir = File::Basename::dirname( $file );
    unless ( write2file( $file, $html ) ) {
        return $app->trans_error( 'Unable to create preview file in this location: [_1]', $file );
    }
    my $sess_obj = MT::Session->get_by_key( { id => $preview_basename,
                                              kind => 'TF',
                                              name => $file,
                                              blog_id => $entry->blog_id,
                                              entry_id => $entry->id,
                                              class => ( $plugin->key || lc ( $plugin->id ) ),
                                            }
                                          );
    $sess_obj->start( time );
    $sess_obj->save;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my $tmpl = 'wf_previewentry.tmpl';
    my %param;
    $param{ blog_name } = $blog->name;
    $param{ blog_id } = $blog->id;
    $param{ page_title } = $plugin->translate( 'Preview Entry' );
    $param{ tmpfile_id } = $sess_obj->id;
    $param{ publish_msg_value } = $class eq 'entry' ? $plugin->translate( 'Publish this Entry?' ) : $plugin->translate( 'Publish this Page?' );
    $param{ entry_id } = $entry->id;
    $param{ object_type } = $class;
    $param{ title } = $entry->title;
    $param{ preview_url } = $permalink;
    $param{ can_publish_post } = is_user_can( $blog, $app->user, 'publish_post' );
    $param{ can_rebuild } = is_user_can( $blog, $app->user, 'rebuild' );
    if ( $entry->has_column( 'owner_id' ) ) {
        if ( $entry->owner_id ) {
            $param{ owner_id } = $entry->owner_id;
        }
    }
    my $edit_uri = $app->base . $app->uri( mode => 'view',
                                           args => { _type => $class,
                                                     id => $id,
                                                     blog_id => $entry->blog_id,
                                                   },
                                         );
    $param{ edit_uri } = $edit_uri;
    my $publish_uri = $app->base . $app->uri( mode => 'preview2publish',
                                              args => { _type => $class,
                                                        id => $id,
                                                        blog_id => $entry->blog_id,
                                                        magic_token => $app->current_magic(),
                                                      },
                                            );
    $param{ publish_uri } = $publish_uri;
    my $sendback_uri = $app->base . $app->uri( mode => 'sendback_dialog', 
                                               args => { _type => $class,
                                                         id => $id,
                                                         blog_id => $entry->blog_id,
                                                       },
                                             );
    $param{ sendback_uri } = $sendback_uri;
    $param{ can_publish } = 1;
    return $app->build_page( $tmpl, \%param );
}

sub _rebuild_entry {
    my ( $entry, $dependencies ) = @_;
    require MT::WeblogPublisher;
    my $pub = MT::WeblogPublisher->new();
    $pub->rebuild_entry( Entry => $entry,
                         BuildDependencies => $dependencies,
                       ) or die ( 'Rebuild error: [_1]', $pub->errstr );
}

sub _mode_manage_perms_for_category {
    my $app = shift;
    my $plugin = MT->component( 'EntryWorkflow' );
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $perms;
    my $blog;
    if ( $blog = $app->blog ) {
        if ( $blog->is_blog ) {
            my $user = $app->user;
            if ( $user->is_superuser ) {
                $perms = 1;
            } elsif ( $user->permissions( $blog->id )->can_administer_blog ) {
                $perms = 1;
            }
        }
    }
    if (! $perms ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog_id = $blog->id;
    my %param;
    my @category_ids = $app->param( 'category_id' );
    my @categories;
    if ( @category_ids ) {
        @categories = MT->model( 'category' )->load( { id => \@category_ids } );
        for my $cat ( @categories ) {
            if ( $blog_id != $cat->blog_id ) {
                return $app->trans_error( 'Invalid request.' );
            }
            if ( $cat->class ne 'category' ) {
                return $app->trans_error( 'Invalid request.' );
            }
        }
    }
    my $id = $app->param( 'author_id' );
    if ( ! $id ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $author = MT->model( 'author' )->load( $id );
    if (! $author ) {
        return $app->trans_error( 'Invalid request.' );
    }
    if (! is_user_can( $blog, $author, 'create_post' ) ) {
        return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
    }
    my $perm = MT->model( 'permission' )->load( { blog_id => $blog->id, author_id => $author->id } );
    if (! $perm ) {
        return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
    }
    if ( $author->is_superuser || $author->permissions( $blog_id )->can_administer_blog ) {
        return $app->error( $plugin->translate( 'User [_1] is administrator.', $author->name ) );
    }
    my @selected_user;
    push ( @selected_user, { author_name => $author->name } );
    $param{ selected_user_loop } = \@selected_user;
    my $categories = $perm->categories;
    my @can_post;
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'update' ) {
        my $changed;
        for my $cat ( @categories ) {
            my $cid = $cat->id;
            if ( ! @can_post || (! grep( /^$cid$/, @can_post ) ) ) {
                push( @can_post, $cid );
                $changed = 1;
            }
        }
        if (! scalar( @categories ) && $categories ) {
            $changed = 1;
        }
        if ( $changed ) {
            $perm->categories( join( ',', @can_post ) );
            $perm->save or die $perm->errstr;
        }
    } else {
        if ( $categories ) {
            @can_post = split( /,/, $categories );
        }
        my $data = $app->_build_category_list(
            blog_id => $blog_id,
            markers => 1,
            type    => 'category',
        );
        my $cat_tree = [];
        foreach ( @$data ) {
            next unless exists $_->{ category_id };
            $_->{ category_path_ids } ||= [];
            unshift @{ $_->{ category_path_ids } }, -1;
            my $current_id = $_->{ category_id };
            my $has_perm;
            if ( grep( /^$current_id$/, @can_post ) ) {
                $has_perm = 1;
            }
            push @$cat_tree,
                {
                category_id => $_->{ category_id },
                has_perm => $has_perm,
                category_label_spacer => '&nbsp;&nbsp;' . ($_->{ category_label_spacer } x 2),
                category_label    => $_->{ category_label },
                category_basename => $_->{ category_basename },
                category_path   => $_->{ category_path_ids } || [],
                category_fields => $_->{ category_fields }   || [],
                };
        }
        $param{ id } = $id;
        $param{ category_tree } = $cat_tree;
        $param{ action } = 'update';
    }
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    my $tmpl = 'category_table.tmpl';
    return $app->build_page( $tmpl, \%param );
}

sub _mode_add_perms_for_category {
    my $app = shift;
    my $plugin = MT->component( 'EntryWorkflow' );
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $perms;
    my $blog;
    if ( $blog = $app->blog ) {
        if ( $blog->is_blog ) {
            my $user = $app->user;
            if ( $user->is_superuser ) {
                $perms = 1;
            } elsif ( $user->permissions( $blog->id )->can_administer_blog ) {
                $perms = 1;
            }
        }
    }
    if (! $perms ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog_id = $blog->id;
    my %param;
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'add' ) {
        my $author_ids = $app->param( 'ids' );
        @ids = split( /,/, $author_ids );
    }
    my @category_ids = $app->param( 'category_id' );
    my @categories;
    if ( @category_ids ) {
        @categories = MT->model( 'category' )->load( { id => \@category_ids } );
        for my $cat ( @categories ) {
            if ( $blog_id != $cat->blog_id ) {
                return $app->trans_error( 'Invalid request.' );
            }
            if ( $cat->class ne 'category' ) {
                return $app->trans_error( 'Invalid request.' );
            }
        }
    }
    my $single_select;
    if ( scalar @ids == 1 ) {
        $single_select = 1;
    }
    my @selected_user;
    my @single_can_post;
    for my $id ( @ids ) {
        my $author = MT->model( 'author' )->load( $id );
        if (! $author ) {
            return $app->trans_error( 'Invalid request.' );
        }
        if (! is_user_can( $blog, $author, 'create_post' ) ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        my $perm = MT->model( 'permission' )->load( { blog_id => $blog->id, author_id => $author->id } );
        if (! $perm ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        if ( $author->is_superuser || $author->permissions( $blog_id )->can_administer_blog ) {
            return $app->error( $plugin->translate( 'User [_1] is administrator.', $author->name ) );
        }
        push ( @selected_user, { author_name => $author->name } );
        my $categories = $perm->categories;
        my @can_post;
        if ( $categories ) {
            @can_post = split( /,/, $categories );
        }
        @single_can_post = @can_post;
        if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'add' ) {
            my $changed;
            for my $cat ( @categories ) {
                my $cid = $cat->id;
                if ( ! @can_post || (! grep( /^$cid$/, @can_post ) ) ) {
                    push( @can_post, $cid );
                    $changed = 1;
                }
            }
            if ( $changed ) {
                $perm->categories( join( ',', @can_post ) );
                $perm->save or die $perm->errstr;
            }
        }
    }
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'add' ) {
    } else {
        my $data = $app->_build_category_list(
            blog_id => $blog_id,
            markers => 1,
            type    => 'category',
        );
        my $cat_tree = [];
        foreach ( @$data ) {
            next unless exists $_->{ category_id };
            $_->{ category_path_ids } ||= [];
            unshift @{ $_->{ category_path_ids } }, -1;
            my $current_id = $_->{ category_id };
            my $has_perm;
            if ( $single_select ) {
                if ( grep( /^$current_id$/, @single_can_post ) ) {
                    $has_perm = 1;
                }
            }
            push @$cat_tree,
                {
                category_id => $_->{ category_id },
                has_perm => $has_perm,
                category_label_spacer => '&nbsp;&nbsp;' . ($_->{ category_label_spacer } x 2),
                category_label    => $_->{ category_label },
                category_basename => $_->{ category_basename },
                category_path   => $_->{ category_path_ids } || [],
                category_fields => $_->{ category_fields }   || [],
                };
        }
        $param{ ids } = join( ',', @ids );
        $param{ category_tree } = $cat_tree;
        $param{ action } = 'add';
    }
    $param{ selected_user_loop } = \@selected_user;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    my $tmpl = 'category_table.tmpl';
    return $app->build_page( $tmpl, \%param );
}

sub _mode_remove_perms_for_category {
    my $app = shift;
    my $plugin = MT->component( 'EntryWorkflow' );
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $perms;
    my $blog;
    if ( $blog = $app->blog ) {
        if ( $blog->is_blog ) {
            my $user = $app->user;
            if ( $user->is_superuser ) {
                $perms = 1;
            } elsif ( $user->permissions( $blog->id )->can_administer_blog ) {
                $perms = 1;
            }
        }
    }
    if (! $perms ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog_id = $blog->id;
    my %param;
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'remove' ) {
        my $author_ids = $app->param( 'ids' );
        @ids = split( /,/, $author_ids );
    }
    my @category_ids = $app->param( 'category_id' );
    my @categories;
    if ( @category_ids ) {
        @categories = MT->model( 'category' )->load( { id => \@category_ids } );
        for my $cat ( @categories ) {
            if ( $blog_id != $cat->blog_id ) {
                return $app->trans_error( 'Invalid request.' );
            }
            if ( $cat->class ne 'category' ) {
                return $app->trans_error( 'Invalid request.' );
            }
        }
    }
    my $single_select;
    if ( scalar @ids == 1 ) {
        $single_select = 1;
    }
    my @selected_user;
    my @single_can_post;
    for my $id ( @ids ) {
        my $author = MT->model( 'author' )->load( $id );
        if (! $author ) {
            return $app->trans_error( 'Invalid request.' );
        }
        if (! is_user_can( $blog, $author, 'create_post' ) ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        my $perm = MT->model( 'permission' )->load( { blog_id => $blog->id, author_id => $author->id } );
        if (! $perm ) {
            return $app->error( $plugin->translate( 'User [_1] has not post permission.', $author->name ) );
        }
        if ( $author->is_superuser || $author->permissions( $blog_id )->can_administer_blog ) {
            return $app->error( $plugin->translate( 'User [_1] is administrator.', $author->name ) );
        }
        push ( @selected_user, { author_name => $author->name } );
        my $categories = $perm->categories;
        my @can_post;
        if ( $categories ) {
            @can_post = split( /,/, $categories );
        }
        @single_can_post = @can_post;
        if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'remove' ) {
            my $changed;
            my @can_post_new;
            if ( @can_post ) {
                for my $cid ( @can_post ) {
                    if (! grep( /^$cid$/, @category_ids ) ) {
                        push ( @can_post_new, $cid );
                    } else {
                        $changed = 1;
                    }
                }
            }
            if ( $changed ) {
                $perm->categories( join( ',', @can_post_new ) );
                $perm->save or die $perm->errstr;
            }
        }
    }
    if ( $app->param( 'action' ) && $app->param( 'action' ) eq 'remove' ) {
    } else {
        my $data = $app->_build_category_list(
            blog_id => $blog_id,
            markers => 1,
            type    => 'category',
        );
        my $cat_tree = [];
        foreach ( @$data ) {
            next unless exists $_->{ category_id };
            $_->{ category_path_ids } ||= [];
            unshift @{ $_->{ category_path_ids } }, -1;
            my $current_id = $_->{ category_id };
            my $has_perm;
            if ( $single_select ) {
                if ( grep( /^$current_id$/, @single_can_post ) ) {
                    $has_perm = 1;
                }
            }
            push @$cat_tree,
                {
                category_id => $_->{ category_id },
                has_perm => $has_perm,
                category_label_spacer => '&nbsp;&nbsp;' . ($_->{ category_label_spacer } x 2),
                category_label    => $_->{ category_label },
                category_basename => $_->{ category_basename },
                category_path   => $_->{ category_path_ids } || [],
                category_fields => $_->{ category_fields }   || [],
                };
        }
        $param{ ids } = join( ',', @ids );
        $param{ category_tree } = $cat_tree;
        $param{ action } = 'remove';
    }
    $param{ selected_user_loop } = \@selected_user;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    my $tmpl = 'category_table.tmpl';
    return $app->build_page( $tmpl, \%param );
}

1;