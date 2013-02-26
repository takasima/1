package PowerRevision::Plugin;
use strict;
use XML::Simple;
use MT::Util qw( encode_html format_ts encode_xml offset_time_list );
use MT::I18N qw( substr_text length_text );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( site_path site_url is_user_can to_utf8 current_user permitted_blog_ids );
use PowerRevision::Util;

use File::Copy::Recursive qw( fcopy rcopy dircopy );

sub _cb_tp_edit_entry_entry_prefs {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $revision_id = $app->param( 'revision_id' ) ) {
        my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
        if ( my $prefs = $revision->prefs ) {
            my @prefs = split( /,/, $prefs );
            my $field_loop = $param->{ field_loop };
            my @new_field_loop;
            for my $hash ( @$field_loop ) {
                if ( grep { $hash->{ field_id } eq $_ } @prefs ) {
                    $hash->{ show_field } = 1;
                } else {
                    $hash->{ show_field } = 0;
                }
            }
        }
    }
}

sub _cb_cms_post_save_powerrevision {
    my ( $eh, $app, $obj, $original, $revision ) = @_;
    my $prefs_type = $app->param( '_type' ) . '_prefs';
    my @prefs = $app->param( 'custom_prefs' );
    $revision->prefs( join( ',', @prefs ) );
    $revision->save or die $revision->errstr;
}

sub _preview_entry {
    my ( $cb, $app, $obj, $data ) = @_;
    push( @$data, { data_name  => 'revision_id',
                    data_value => $app->param( 'revision_id' ),
                  },
        );
    push( @$data, { data_name  => 'update_revision',
                    data_value => $app->param( 'update_revision' ),
                  },
        );
    push( @$data, { data_name  => 'orig_id',
                    data_value => $app->param( 'orig_id' ),
                  },
        );
    push( @$data, { data_name  => 'revision_comment',
                    data_value => $app->param( 'revision_comment' ),
                  },
        );
    if ( $app->param( 'orig_id' ) ) {
        if (! $app->param( 'revision_id' ) ) {
            push( @$data, { data_name  => 'duplicate',
                            data_value => 1,
                          },
                );
            push( @$data, { data_name  => 'is_revision',
                            data_value => 1,
                          },
                );
        }
    }
}

sub _cb_entryworkflow_post_sendback {
    my ( $cb, $app, $entry, $return_url, $change_author, $revision ) = @_;
    return unless $revision;
    return _set_approver_ids_to_obj( $app, $revision, $change_author->id );
}

sub _cb_entryworkflow_post_change_author {
    my ( $cb, $app, $obj, $revision, $change_author ) = @_;
    return unless $revision;
    return _set_approver_ids_to_obj( $app, $revision, $change_author->id );
}

sub _set_approver_ids_to_obj {
    my ( $app, $obj, @approver_ids ) = @_;
    return unless $obj;
    eval{
        require EntryWorkflow::Util;
    };
    unless ( $@ ) {
        my $user = current_user( $app );
        $obj = EntryWorkflow::Util::set_approver_ids_to_obj( $obj, $user->id, @approver_ids );
        $obj->save or die $obj->errstr;
    }
}

sub _backup_entry {
    my ( $cb, $app, $obj, $original ) = @_;
    my $class = $obj->class;
    if ( ( $class ne 'entry' ) && ( $class ne 'page' ) ) {
        return;
    }
    my $orig_id = $app->param( 'orig_id' );
    if ( $obj->id < 0 ) {
        if ( $orig_id ) {
            $obj->save or die $obj->errstr;
        }
    }
    my $plugin = MT->component( 'PowerRevision' );
    my $mode = $app->mode;
    my $blog = $app->blog;
    my $ex_status = $app->param( 'ex_status' );
    my $revision_id = $app->param( 'revision_id' );
    my $history = $blog->max_revisions_entry || $MT::Revisable::MAX_REVISIONS;
    my $backup_dir = PowerRevision::Util::backup_dir();
    my $count = MT->model( 'powerrevision' )->count( { blog_id   => $obj->blog_id,
                                                       object_ds => 'entry',
                                                       object_id => abs ( $obj->id ),
                                                       object_class => $class,
                                                       class => 'backup',
                                                     }
                                                   );
    my $revision; my @histories;
    if ( $count ) {
        @histories = MT->model( 'powerrevision' )->load( { blog_id   => $obj->blog_id,
                                                           object_ds => 'entry',
                                                           object_id => abs ( $obj->id ),
                                                           object_class => $class,
                                                           class => 'backup',
                                                         },
                                                       );
    }
    if ( $history <= $count ) {
        $revision = MT->model( 'powerrevision' )->load( { blog_id   => $obj->blog_id,
                                                          object_ds => 'entry',
                                                          object_id => abs ( $obj->id ),
                                                          object_class => $class,
                                                          class => 'backup',
                                                         }, {
                                                          'sort' => 'modified_on',
                                                          direction => 'ascend',
                                                          limit => 1,
                                                         }
                                                      );
    }
    if ( $revision_id ) {
        $revision = MT->model( 'powerrevision' )->load( { blog_id => $obj->blog_id,
                                                          id => $revision_id,
                                                        }
                                                      );
    }
    my @tl = offset_time_list( time, $blog );
    my $ts = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
    unless ( defined $revision ) {
        $revision = MT->model( 'powerrevision' )->new;
        $revision->blog_id( $obj->blog_id );
        $revision->website_id( $obj->blog->parent_id );
        $revision->object_ds( 'entry' );
        $revision->object_id( abs ( $obj->id ) );
        $revision->object_class( $class );
        $revision->created_on( $ts );
    }
    $revision->obj_auth_on( $obj->authored_on );
    if ( $obj->id < 0 ) {
        $revision->status( $obj->status );
        if ( $ex_status ) {
            if ( $ex_status == MT::Entry::FUTURE() ) {
                $revision->class( 'workflow' );
                $revision->future_post( 0 );
            }
            if ( $ex_status == MT::Entry::REVIEW() ) {
                $revision->class( 'workflow' );
            }
        } else {
            if ( $obj->status == MT::Entry::FUTURE() ) {
                $revision->class( 'workflow' );
                $revision->future_post( 0 );
            }
            if ( $obj->status == MT::Entry::REVIEW() ) {
                $revision->class( 'workflow' );
            }
        }
    } else {
        $revision->status( MT::Entry::HOLD() );
    }
    $revision->author_id( $obj->author_id );
    if ( $obj->has_column( 'owner_id' ) ) {
        $revision->owner_id( $obj->owner_id );
    }
    if ( ( ! $revision->id ) && ( $revision->class eq 'workflow' ) ) {
        $revision->owner_id( $app->user->id );
    }
    if ( $orig_id ) {
        if (! $revision_id ) {
            $revision->class( 'workflow' );
        }
    }
    unless ( $revision->class ) {
        $revision->class( 'backup' );
        $revision->status( MT::Entry::HOLD() );
    }
    if ( $revision->status == MT::Entry::RELEASE() ) {
        $revision->status( MT::Entry::HOLD() );
    }
    if ( ( $revision->class eq 'workflow' ) || ( $obj->id < 0 ) ) {
        my $orig_obj = MT::Entry->load( abs ( $obj->id ) );
        if ( defined $orig_obj ) {
            $revision->entry_status( $orig_obj->status );
            $obj->basename( $orig_obj->basename );
            $obj->save or die $obj->errstr;
        }
    } else {
        if ( $ex_status ) {
            $revision->entry_status( $ex_status );
        } else {
            $revision->entry_status( $obj->status );
        }
    }
    $revision->modified_on( $ts );
    if ( ( $mode eq 'save_entry' ) || ( $mode eq 'save_page' ) ) {
        $revision->comment( $app->param( 'revision_comment' ) );
        $revision->object_name( $obj->title );
    } else {
        if ( $mode eq 'save_entries' ) {
            my $batch_comment = '( ' . $plugin->translate( 'Batch Edit Entries' ) . ' )';
            $obj->revision_comment( $batch_comment );
            $obj->save or die $obj->errstr;
            $revision->object_name( $obj->title );
            $revision->comment( $batch_comment );
        } elsif ( $mode eq 'save_pages' ) {
            my $batch_comment = '( ' . $plugin->translate( 'Batch Edit Pages' ) . ' )';
            $obj->revision_comment( $batch_comment );
            $obj->save or die $obj->errstr;
            $revision->object_name( $obj->title );
            $revision->comment( $batch_comment );
        } else {
            $revision->object_name( $obj->title );
        }
    }
    my ( $xml, $assets ) = PowerRevision::Util::build_entry_xml( $obj );
    if ( $cb eq 'recover_entry' ) {
        if ( $xml eq $original ) {
            return ( $xml, undef );
        }
    }
    my $fmgr = $blog->file_mgr;
    if ( scalar @histories ) {
        # my $no_update;
        for my $history ( @histories ) {
            my $history_xml = File::Spec->catdir( $backup_dir, $history->id . '.xml' );
            unless ( $fmgr->content_is_updated( $history_xml, \$xml ) ) {
                $history->modified_on( $ts );
                $history->comment( $app->param( 'revision_comment' ) ) if $app->param( 'revision_comment' );
                $history->save or die $history->errstr;
                $history->object_name( $obj->title );
                return 1;
            }
        }
    }
    $revision->object_status( 2 );
    $revision->save or die $revision->errstr;
    $app->run_callbacks( 'cms_post_save.powerrevision', $app, $obj, $original, $revision );
    if ( $revision->status == MT::Entry::RELEASE() ) {
        $revision->status( MT::Entry::HOLD() );
        $revision->save or die $revision->errstr;
    }
    my $new_xml = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
    $fmgr->put_data( $xml, "$new_xml.new" );
    $fmgr->rename( "$new_xml.new", $new_xml );
    unless ( $fmgr->exists( $new_xml ) ) {
        $app->log( $plugin->translate( 'Can\'t create backup file.' ) );
        $revision->remove or die $revision->errstr;
        return 1;
    }
    if ( scalar @$assets ) {
        my $asset_dir = File::Spec->catdir( $backup_dir, 'assets' );
        unless ( $fmgr->exists( $asset_dir ) ) {
            $fmgr->mkpath( $asset_dir )
                or die MT->translate( "Error making path '[_1]': [_2]", $asset_dir, $fmgr->errstr );
        }
        my $revision_dir = File::Spec->catdir( $asset_dir, $revision->id );
        unless ( $fmgr->exists( $revision_dir ) ) {
            $fmgr->mkpath( $revision_dir )
                or die MT->translate( "Error making path '[_1]': [_2]", $revision_dir, $fmgr->errstr );
        }
        for my $asset ( @$assets ) {
            my $file_path = $asset->file_path;
            my $file_name = $asset->id . '.' . $asset->file_ext;
            my $copy_dir = File::Spec->catdir( $revision_dir, 'items' );
            my $copy_path = File::Spec->catdir( $revision_dir, 'items', $file_name );
            my $original;
            my @stats = stat( $file_path );
            my $org_modified = $stats[ 9 ];
            my $org_size = $stats[ 7 ];
            if ( scalar @histories ) {
                for my $history ( @histories ) {
                    my $asset_hist_xml = File::Spec->catdir( $backup_dir, 'assets', $history->id, $asset->id . '.xml' );
                    if ( $fmgr->exists( $asset_hist_xml ) ) {
                        my $xmlsrc = $fmgr->get_data( $asset_hist_xml );
                        my $xmlsimple = XML::Simple->new();
                        my $asset_hist = $xmlsimple->XMLin( $xmlsrc );
                        my $backuppath = $asset_hist->{ backuppath };
                        $backuppath =~ s/^%b/$backup_dir/;
                        if ( $fmgr->exists( $backuppath ) ) {
                            my @cp_stats = stat( $backuppath );
                            my $copy_modified = $cp_stats[ 9 ];
                            my $copy_size = $cp_stats[ 7 ];
                            if ( ( $copy_size == $org_size ) && ( $copy_modified == $org_modified ) ) {
                                $original = $backuppath;
                                next;
                            }
                        }
                    }
                }
            }
            unless ( $original ) {
                unless ( $fmgr->exists( $copy_dir ) ) {
                    $fmgr->mkpath( $copy_dir )
                        or die MT->translate( "Error making path '[_1]': [_2]", $copy_dir, $fmgr->errstr );
                }
                fcopy( $file_path, "$copy_path.new" );
                $fmgr->rename( "$copy_path.new", $copy_path );
                utime( $org_modified, $org_modified, $copy_path );
            } else {
                $copy_path = $original;
            }
            $copy_path =~ s/^$backup_dir/%b/;
            my $asset_xml = _build_asset_xml( $blog, $asset, $copy_path );
            my $asset_xml_path = File::Spec->catdir( $revision_dir, $asset->id . '.xml' );
            $fmgr->put_data( $asset_xml, "$asset_xml_path.new" );
            $fmgr->rename( "$asset_xml_path.new", $asset_xml_path );
        }
    }
    if ( $cb eq 'recover_entry' ) {
        return ( $xml, $revision );
    }
    if ( $obj->id < 0 ) {
        if ( $orig_id ) {
            my $obj_type = $obj->class;
            $obj->remove or die $obj->errstr;
            my $match = '%(ID:' . $obj->id . ')%';
            MT->run_callbacks( "cms_post_delete.$obj_type", $app, $obj, $obj );
            use MT::Log;
            my @logs = MT::Log->load( { blog_id => $obj->blog_id,
                                        category => [ 'new', 'edit', 'delete' ],
                                        class => [ 'entry', 'system' ],
                                        message => { like => $match },
                                      }, {
                                        limit => 2,
                                        'sort'  => 'id',
                                        direction  => 'descend',
                                      }
                                    );
            for my $log ( @logs ) {
                $log->remove or die $obj->errstr;
            }
            my $return_url = $app->uri( mode => 'edit_revision',
                                        args => { 'blog_id' => $obj->blog_id,
                                                  '_type' => $obj_type,
                                                  'entry_id' => $orig_id,
                                                  'revision_id' => $revision->id,
                                                  'saved_changes' => 1,
                                                }
                                      );
            MT->run_callbacks( "cms_pre_redirect.$obj_type", $app, \$return_url, $revision, $obj, $original );
            return $app->print( "Location: " . $return_url . "\n\n" );
        }
    }
1;
}

sub _edit_entry_output {
    my ( $cb, $app, $tmpl ) = @_;
    if ( ( $app->param( 'edit_revision' ) ) && ( $app->param( 'id' ) < 0 ) ) {
        if ( ( is_user_can( $app->blog, $app->user, 'create_post' ) ) ||
             ( is_user_can( $app->blog, $app->user, 'manage_pages' ) ) ) {
            my $entry = MT::Entry->load( $app->param( 'id' ) );
            if ( defined $entry ) {
                $entry->remove or die $entry->errstr;
            }
        } else {
            $$tmpl = $app->translate( 'Permission denied.' );
        }
    }
}

sub _set_extra_status {
    my ( $cb, $app, $obj, $org ) = @_;
    my $ex_status = $app->param( 'ex_status' );
    if ( $ex_status ) {
        if ( $ex_status == MT::Entry::RELEASE() || $ex_status == MT::Entry::FUTURE() ) {
            if ( is_user_can( $obj->blog, $app->user, 'publish_post' ) ) {
                $obj->status( $ex_status );
            }
        } elsif ( $ex_status == 7 ) {
            if ( is_user_can( $obj->blog, $app->user, 'edit_templates' ) ) {
                $obj->status( $ex_status );
            }
        } elsif ( $ex_status == MT::Entry::HOLD() ) {
            $obj->status( $ex_status );
        } elsif ( $ex_status == MT::Entry::REVIEW() ) {
            $obj->status( $ex_status );
        }
        unless ( $obj->status ) {
            $obj->status( MT::Entry::HOLD() );
        }
    }
    if ( ! $org && ! $obj->created_by ) {
        $obj->created_by( $app->user->id );
    }
1;
}

sub _author_check_on_release {
    my ( $cb, $app, $obj, $org ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $orig_id = $app->param( 'orig_id' );
    return 1 unless $orig_id;
    my $entry = MT::Entry->load( { id => abs $orig_id } );
    return 1 unless $entry;
    return 1 if $app->param( 'ex_status' ) != MT::Entry::RELEASE();
    return 1 unless is_user_can( $obj->blog, $app->user, 'publish_post' );
    my $user_id = $app->user->id;
    my $entry_author_id = $entry->author_id;
    my $entry_owner_id  = $entry->has_column( 'owner_id' ) ? $entry->owner_id : 'DUMMY';
    if ( $entry_author_id ) {
        if ( my $obj_author_id = $obj->author_id ) {
            if ( $obj_author_id == $entry_author_id && $entry_author_id == $user_id ) {
                return 1; # do nothing
            }
            $app->log( $plugin->translate( 'callback obj->author_id:[_1] is differ from entry([_2])->author_id:[_3].(app->user->id:[_4])', $obj_author_id, $entry->id, $entry_author_id, $user_id ) );
        }
        # change author_id and owner_id
        $obj->author_id( $user_id );
        $obj->owner_id( $entry_author_id ) unless $entry_owner_id;
        return 1;
    }
    $app->log( $plugin->translate( 'Can\'t get author_id from entry object :[_1]', $entry->id ) );
    # no author_id
    $obj->author_id( $user_id );
    return 1 if $entry_owner_id;
    # need to set owner_id
    if ( $entry_author_id != $user_id ) {
        $obj->owner_id( $entry_author_id );
    }
    return 1;
}

sub _save_future {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( my $orig_id = $app->param( 'orig_id' ) ) {
        if ( $app->param( 'ex_status' ) != MT::Entry::RELEASE() ) {
            $obj->id( $orig_id * -1 );
            unless ( $obj->author_id ) {
                $obj->author_id( $app->user->id );
            }
        } else {
            $obj->id( abs $orig_id );
            $obj->status( MT::Entry::RELEASE() );
            my $revision_id = $app->param( 'revision_id' );
            my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
            if ( $revision ) {
                if ( $revision->class ne 'backup' ) {
                    $revision->class( 'backup' );
                    $revision->save or die $revision->errstr;
                }
            }
            MT->run_callbacks( 'cms_post_recover.' . $obj->class, $app, $obj, $revision );
        }
        my $entry = MT::Entry->load( { id => abs $orig_id } );
        if ( $entry ) {
            $obj->basename( $entry->basename );
        }
    }
    return 1;
}

sub _delete_blog {
    my ( $cb, $app, $obj, $original ) = @_;
    my @revisions = MT->model( 'powerrevision' )->load( { blog_id => $obj->id } );
    for my $revision ( @revisions ) {
        $revision->remove or die $revision->errstr;
    }
}

sub _search_powerrevision {
    my $app = shift;
    my $plugin = MT->component( 'PowerRevision' );
    my ( %args ) = @_;
    my @permitted_blog_ids = permitted_blog_ids( $app,
                                                 [ 'administer_blog',
                                                   'edit_all_posts',
                                                   'publish_post',
                                                   'create_post',
                                                   'manage_pages',
                                                 ],
                                               );
    unless ( @permitted_blog_ids ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my %blogs;
    for my $permitted_blog_id ( @permitted_blog_ids ) {
        my $permitted_blog = MT::Blog->load( { id => $permitted_blog_id } );
        if ( $permitted_blog ) {
            $blogs{ $permitted_blog->id } = $permitted_blog;
        }
    }
    my $class = $app->model( 'powerrevision' );
    my $list_pref = $app->list_pref( 'powerrevision' );
    my $iter;
    if ( $args{ load_args } ) {
        $iter = $class->load_iter( @{ $args{ load_args } } );
    } elsif ( $args{ iter } ) {
        $iter = $args{ iter };
    } elsif ( $args{ items } ) {
        $iter = sub { pop @{ $args{ items } } };
    }
    return [] unless $iter;
    my $limit = $args{ limit };
    my $param = $args{ param } || {};
    my @data;
    my %perms;
    my $user = $app->user;
    while ( my $obj = $iter->() ) {
        my $row = $obj->column_values;
        $row->{ object } = $obj;
        my $columns = $obj->column_names;
        my $admin = is_user_can( $obj->blog, $user, 'administer_blog' );
        my $edit_all_posts = is_user_can( $obj->blog, $user, 'edit_all_posts' );
        my $publish_post = is_user_can( $obj->blog, $user, 'publish_post' );
        my $manage_pages = is_user_can( $obj->blog, $user, 'manage_pages' );
        my $create_post = is_user_can( $obj->blog, $user, 'create_post' );
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column eq 'comment' ) {
                $val = substr_text( $val, 0, 40 ) . ( length_text( $val ) > 40 ? "..." : "" );
            }
            if ( $column eq 'object_name' ) {
                $val = substr_text( $val, 0, 30 ) . ( length_text( $val ) > 30 ? "..." : "" );
            }
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085; %H:%M:%S", $val, undef, $app->user ? $app->user->preferred_language : undef );
            }
            $row->{ $column } = $val;
            if ( ( $edit_all_posts ) || ( $admin ) ) {
                $row->{ 'can_edit_revision' } = 1;
                unless ( $publish_post ) {
                    if ( $obj->object_status == 2 ) {
                        my $entry = MT::Entry->load( { id => $obj->object_id } );
                        if ( defined $entry ) {
                            if ( $entry->status == MT::Entry->RELEASE() ) {
                                $row->{ 'can_edit_revision' } = 0;
                            }
                        }
                    }
                }
            } elsif ( $manage_pages ) {
                my $entry = MT::Entry->load( { id => $obj->object_id } );
                if ( defined $entry ) {
                    if ( $entry->class eq 'page' ) {
                        $row->{ 'can_edit_revision' } = 1;
                        unless ( $publish_post ) {
                            if ( $obj->object_status == 2 ) {
                                my $entry = MT::Entry->load( { id => $obj->object_id } );
                                if ( defined $entry ) {
                                    if ( $entry->status == MT::Entry->RELEASE() ) {
                                        $row->{ 'can_edit_revision' } = 0;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if ( $user->id == $obj->author_id ) {
                        $row->{ 'can_edit_revision' } = 1;
                    }
                }
            } elsif ( $user->id == $obj->author_id ) {
                if ( $create_post ) {
                    $row->{ 'can_edit_revision' } = 1;
                }
            }
            $row->{ can_edit_revision } = PowerRevision::Util::if_user_can_revision( $obj, $user, 'edit_revision' );
            unless ( defined $app->blog ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
                $row->{ 'blog_name' } = $blog_name;
            }
        }
        push @data, $row;
        last if $limit and @data > $limit;
    }
    return [] unless @data;
    unless ( $app->param( 'blog_id' ) ) {
        $param->{ 'system_view' } = 1;
    }
    $param->{ 'search_label' } = $plugin->translate( 'Revision' );
    $param->{ 'is_search' } = 1;
    $param->{ 'object_loop' } = \@data;
    \@data;
}

sub _transform_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $pointer_field = $tmpl->getElementById( 'hidden_etc' ) ) {
        my $nodeset = $tmpl->createElement( 'for',
                                            { id => 'hidden_etc_powerrevision',
                                              label_class => 'no-label',
                                            }
                                          );
        my $innerHTML =<<'MTML';
<mt:if name="orig_id">
    <input type="hidden" name="orig_id" value="<$mt:var name="orig_id" escape="html"$>" />
</mt:if>
<mt:if name="revision_id">
    <input type="hidden" name="revision_id" value="<$mt:var name="revision_id" escape="html"$>" />
    <input type="hidden" name="update_revision" value="1" />
</mt:if>
<input type="hidden" name="status" value="<$mt:var name="status" escape="html"$>" />
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer_field );
    }
    if ( my $pointer_field = $tmpl->getElementById( 'msg_block_etc' ) ) {
        my $nodeset = $tmpl->createElement( 'for',
                                            { id => 'msg_block_etc_powerrevision',
                                              label_class => 'no-label',
                                            }
                                          );
        my $innerHTML =<<'MTML';
    <mt:if name="is_powerrevision">
    <$mt:setvar name="page_title" value="<__trans_section component="PowerRevision"><__trans phrase="New Revision"></__trans_section>"$>
    </mt:if>
    <mt:if name="edit_powerrevision">
    <$mt:setvar name="page_title" value="<__trans_section component="PowerRevision"><__trans phrase="Edit Revision"></__trans_section>"$>
    </mt:if>
    <mt:if name="is_powerrevision">
            <mtapp:statusmsg
                id="is_powerrevision"
                class="info">
                    <mt:var name="page_title">
            </mtapp:statusmsg>
    </mt:if>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer_field );
    }
}

sub _edit_entry_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $entry_id = $app->param( 'id' );
    my $revision_id = $app->param( 'revision_id' );
    if ( $entry_id && ( $entry_id < 0 ) ) {
        if ( $revision_id ) {
            $param->{ id } = '';
            $param->{ orig_id } = abs( $entry_id );
        }
    }
    if ( $app->param( 'is_revision' ) ) {
        $param->{ is_powerrevision } = 1;
        if ( $entry_id ) {
            my $class_type = $app->param( '__type' ) || 'entry';
            my $e = $app->model( $class_type )->load( { id => $entry_id } );
            if ( $e ) {
                $param->{ basename } = $e->basename;
            }
        }
        $param->{ status_publish } = 0;
        $param->{ status_draft } = 1;
    }
    my $revision_comment;
    my $reedit = $app->param( 'reedit' );
    if ( $revision_id ) {
        my $revision = MT->model( 'powerrevision' )->load( { id => $app->param( 'revision_id' ),
                                                             object_ds => 'entry',
                                                           }
                                                         );
        if ( $revision ) {
            $revision_comment = $revision->comment;
        }
        $param->{ is_powerrevision } = 1;
        $param->{ edit_powerrevision } = 1;
        unless ( $reedit ) {
            if ( defined $revision ) {
                my $revision_status = $revision->status;
                $param->{ status } = $revision_status;
                if ( $revision_status != MT::Entry::HOLD() ) {
                    $param->{ status_publish } = 0;
                    $param->{ status_draft } = 0;
                    $param->{ status_future } = 0;
                    if ( $revision_status == MT::Entry::FUTURE() ) {
                        $param->{ status_future } = 1;
                    }
                }
            }
        }
    }
    my $blog_id = $app->blog->id;
    my $class = $app->param( '_type' );
    if ( my $remove_node = $tmpl->getElementById( 'revision-note' ) ) {
        $remove_node->setAttribute( 'class', 'display-none' );
    }
    if ( my $pointer_field = $tmpl->getElementById( 'basename' ) ) {
        my $nodeset = $tmpl->createElement( 'app:setting',
                                            { id => 'revision_comment',
                                              label => $plugin->translate( 'Comment for revision' ),
                                              label_class => 'top-label',
                                              required => 0,
                                              style => 'display:none;'
                                            }
                                          );
        my $innerHTML = '<div class="textarea-wrapper">';
        if ( $revision_comment ) {
            $innerHTML .= '<input class="full-width" name="revision_comment" id="revision_comment" type="text" value="' . $revision_comment . '" style="margin-top : 0px" />';
        } else {
            $innerHTML .= '<input class="full-width" name="revision_comment" id="revision_comment" type="text" value="<$mt:var name="revision_comment" escape="html"$>" style="margin-top : 0px" />';
        }
        $innerHTML .= '</div>';
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer_field );
        $param->{ revision_comment } = '';
    }
    if ( (! $reedit ) && ( $app->param( 'duplicate' ) ) ) {
        if ( $app->param( 'is_revision' ) ) { # new edit
            $param->{ id } = '';
            $param->{ orig_id } = $app->param( 'id' );
            $param->{ new_object } = 1;
        }
        return;
    }
    my @revisions;
    if (! $app->param( 'orig_id' ) ) {
        @revisions = MT->model( 'powerrevision' )->load( { object_id => $entry_id,
                                                           object_ds => 'entry',
                                                           class => 'backup',
                                                         }, { 'sort' => 'modified_on',
                                                           direction => 'descend',
                                                         }
                                                       );
    }
    if ( @revisions ) {
        if ( my $pointer_field = $tmpl->getElementById( 'basename' ) ) {
            my $revision_url = $app->base . $app->uri( mode => 'select_powerrevision',
                                                       args => { filter => 'object_id',
                                                                 filter_val => $entry_id,
                                                                 blog_id    => $blog_id,
                                                                 class_type => 'backup',
                                                                 dialog     => 1,
                                                               },
                                                     );
#             my $revision_url = $app->base . $app->uri( mode => 'list',
#                                                        args => { _type => 'powerrevision',
#                                                                  filter => 'object_id',
#                                                                  filter_val => $entry_id,
#                                                                  blog_id    => $blog_id,
#                                                                  class_type => 'backup',
#                                                                  dialog     => 1,
#                                                                },
#                                                      );
            my $revision_title = $plugin->translate( 'View revisions list' );
            my $label = '<a class="mt-open-dialog" title="' . $revision_title . '" href="' . $revision_url . '">' . $plugin->translate( 'History' ) . '</a>';
            my $nodeset = $tmpl->createElement( 'app:setting',
                                                { id => 'entry_history',
                                                  label => $label,
                                                  label_class => 'top-label',
                                                  required => 0,
                                                }
                                              );
            my $innerHTML = '<span style="white-space:nowrap"><select name="entry_history" id="entry_history" style="margin-bottom:0px;width:190px">';
            for my $revision ( @revisions ) {
                my $ts = format_ts( "%Y/%m/%d %H:%M:%S", $revision->modified_on, $app->blog, $app->user ? $app->user->preferred_language : undef );
                $innerHTML .= '<option value="' . $revision->id . '">';
                my $comment = substr_text( $revision->comment, 0, 12 )
                  . ( length_text( $revision->comment ) > 12 ? "..." : "" );
                $innerHTML .= $ts . '&nbsp; ' . $comment . '</option>';
            }
            $innerHTML .= '</select>';
            $innerHTML .= ' <a title="' . $plugin->translate( 'Recover from history' ) . '" href="javascript:recover_from_history();" onclick="return confirm(\'';
            $innerHTML .= $plugin->translate( 'Are you sure you want to recover this [_1]?', $plugin->translate( $class ) );
            $innerHTML .= '\' )"><img width="8" width="9" src="' . $app->static_path . 'addons/PowerCMS.pack/images/revision.gif" alt="' . $plugin->translate( 'Recover from history' ) . '" /></a>';
            $innerHTML .= ' &nbsp;<a title="' . $plugin->translate( 'View history' ) . '" href="javascript:void(0);" onclick="view_history();">';
            $innerHTML .= '<img width="13" width="9" src="' . $app->static_path . '/images/status_icons/view.gif" alt="' . $plugin->translate( 'View history' ) . '" /></a></span>';
            my $url = $app->base . $app->uri( mode => 'recover_entry',
                                              args => { blog_id  => $blog_id,
                                                        entry_id => $entry_id,
                                                        _type    => $class,
                                                       },
                                            );
            my $preview_url = $app->base . $app->uri( mode => 'preview_history',
                                                      args => { blog_id => $blog_id,
                                                                entry_id => $entry_id,
                                                                _type     => $class,
                                                              },
                                                    );
            $innerHTML .= <<MTML;
<script type="text/javascript">
    function recover_from_history () {
        var recover = getByID( 'entry_history' );
        var recover_id = recover.value;
        var url = '$url&revision_id=';
        url += recover.value;
        location.href = url;
    }
    function view_history () {
        var recover = getByID( 'entry_history' );
        var recover_id = recover.value;
        var url = '$preview_url&revision_id=';
        url += recover.value;
        window.open( url, '_blank' );
    }
</script>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer_field );
        }
    }
    $param->{ use_revision } = 0;
    $param->{ revision_id } = $app->param( 'revision_id' );
    if ( $reedit ) {
        $param->{ orig_id } = $app->param( 'orig_id' );
        $param->{ revision_comment } = $app->param( 'revision_comment' );
        $param->{ revision_id } = $app->param( 'revision_id' );
        $param->{ update_revision } = $app->param( 'update_revision' );
        if ( $app->param( 'orig_id' ) && ! $app->param( 'revision_id' ) ) { # edit new revision, and return from preview
            $param->{ use_revision } = 1;
        }
    }
    unless ( is_user_can( $app->blog, $app->user, 'publish_post' ) ) {
        $param->{ can_publish_post } = 0;
        $param->{ can_manage_pages } = 0;
    }
}

sub _recovered_msg {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $class = $app->param( '_type' );
    my $recovered = $app->param( 'recovered' );
    my $not_recovered = $app->param( 'not_recovered' );
    my $no_xml = $app->param( 'no_xml' );
    if ( ( ! $recovered  ) && ( ! $not_recovered ) && ( ! $no_xml ) ) {
        return;
    }
    my $label;
    if ( $recovered ) {
        my $backup_revision_id = $app->param( 'backup_revision_id' );
        my $entry = MT::Entry->load( { id => $app->param( 'id' ) } );
        if ( defined $entry ) {
            if ( $entry->status == MT::Entry::RELEASE() ) {
                $label = $plugin->translate( '[_1] is recovered from backup. Publish[_1] your site to see these changes take effect.', encode_html( $plugin->translate( $class ) ) );
            } else {
                $label = $plugin->translate( '[_1] is recovered from backup.', encode_html( $plugin->translate( $class ) ) );
            }
            if ( $backup_revision_id ) {
                my $url = $app->uri( mode => 'recover_entry',
                                     args => { blog_id => $app->blog->id,
                                               entry_id => $app->param( 'id' ),
                                               revision_id => $backup_revision_id,
                                               _type => $class,
                                             },
                                   );
                my $msg = $plugin->translate( 'Are you sure you want to recover to last update this [_1]?', encode_html( $plugin->translate( $class ) ) );
                $label .= '<a href="' . $url . '" onclick="return confirm(\'' . $msg . '\' )">';
                $label .= $plugin->translate( '(Recover [_1] to last update.)', encode_html( $plugin->translate( $class ) ) );
                $label .= '</a>';
            }
        }
    }
    if ( $not_recovered ) {
        $label = $plugin->translate( '[_1] is not recovered from backup. [_1] data is equal to revison data.', encode_html( $plugin->translate( $class ) ) );
    }
    if ( $no_xml ) {
        $class =~ s/(^.)/uc($1)/e;
        $label = $plugin->translate( '[_1] is not recovered from backup (XML file was not found).', encode_html( $plugin->translate( $class ) ) );
    }
    my $search = quotemeta( '<mt:if name="saved_added">' );
    my $insert =<<MTML;
    <mt:unless name="saved_changes">
    <mtapp:statusmsg
        id="recovered"
        class="success">
        $label
        </a>
    </mtapp:statusmsg>
    </mt:unless>
MTML
    $$tmpl =~ s/($search)/$insert$1/g;
}

sub _delete_entry_flag {
    my ( $cb, $app, $obj, $original ) = @_;
    my @revisions = MT->model( 'powerrevision' )->load( { object_id => $obj->id,
                                                          object_ds => 'entry',
                                                        }
                                                      );
    for my $revision ( @revisions ) {
        $revision->object_status( 1 );
        $revision->save or die $revision->errstr;
    }
}

sub _build_asset_xml {
    my ( $blog, $asset, $copy_path ) = @_;
    my $site_path = site_path( $blog );
    $site_path = quotemeta( $site_path );
    my $site_url = site_url( $blog );
    my $asset_column_names = $asset->column_names;
    my $res = "<powercms xmlns='http://alfasado.net/power_cms/ns/'>\n";
    $res .= "<mtasset>\n";
    for my $name ( @$asset_column_names ) {
        my $val = $asset->$name;
        if ( $name eq 'file_path' ) {
            $val =~ s/^$site_path/%r/;
        } elsif ( $name eq 'url' ) {
            $val =~ s/^$site_url/%r/;
        }
        $res .= "<asset_$name>" . encode_xml( $val ) . "</asset_$name>\n";
    }
    $res .= "</mtasset>\n";
    $res .= "<backuppath>" . encode_xml( $copy_path ) . "</backuppath>\n";
    $res .= '</powercms>';
    if ( MT->config->PublishCharset ne 'UTF-8' ) {
        $res = to_utf8( $res );
    }
    return $res;
}

sub _check_asset {
    my ( $app, $blog, $obj, $src, $file, $site_path,
         $site_url, $doc_root, $save, $org_asset, $save_asset ) = @_;
    my $path = $src;
    my $full_path;
    if ( $path =~ m!^\.\./! ) {
        $path = File::Spec->rel2abs( $path, $file );
        unless ( -f $path ) {
            $path = File::Spec->rel2abs( $src, $app->document_root. $app->path );
        }
        unless ( -f $path ) {
            return $src;
        }
        my $match;
        while (! $match ) {
            my $orginal = $path;
            $path =~ s!/[^/]*?/\.\./!/!sg;
            if ( $orginal eq $path ) {
                $match = 1;
            }
        }
        $full_path = $path;
        $path =~ s/$site_path/%r/;
    } elsif ( $path =~ /^$site_url/ ) {
        $path =~ s/$site_url/%r/;
        $full_path = $path;
        $full_path =~ s/%r/$site_path/;
    } elsif ( $path =~ m!^/(.*)! ) {
        $path = File::Spec->catfile( $doc_root, $1 );
        $full_path = $path;
        $path =~ s/$site_path/%r/;
    }
    if ( $full_path ) {
        if ( -f $full_path ) {
            require MT::FileInfo;
            my $fileinfo = MT::FileInfo->load( { file_path => $full_path } );
            unless ( defined $fileinfo ) {
                my $asset = MT->model( 'asset' )->load( { class => '*',
                                                          url   => $path,
                                                        }
                                                      );
                if ( defined $asset ) {
                    my $objectasset = MT->model( 'objectasset' )->get_by_key( { asset_id => $asset->id,
                                                                                object_id => $obj->id,
                                                                                object_ds => 'entry',
                                                                                blog_id => $blog->id
                                                                              }
                                                                            );
                    unless ( $objectasset->id ) {
                        if ( $save ) {
                            $objectasset->save
                                    or die $app->trans_error( 'Error saving objectasset: [_1]', $objectasset->errstr );
                        }
                    } else {
                        if ( $save ) {
                            push ( @{ $save_asset }, $objectasset->id );
                        } else {
                            push ( @{ $org_asset }, $objectasset );
                        }
                    }
                }
            }
        }
    }
    if ( $path =~ /^%r/ ) {
        $path =~ s/%r/$site_url/;
        return $path;
    } else {
        return $src;
    }
    return $src;
}

sub _list_powerrevision {
    my $app = shift;
    my $plugin = MT->component( 'PowerRevision' );
    my $perms = $app->permissions;
    my $user  = $app->user;
    my $admin = $user->is_superuser
      || ( $perms && $perms->can_administer_blog );
    my $edit_all_posts = $admin
      || ( $perms
        && ( $perms->can_edit_all_posts ) )
      ? 1 : 0;
    my $publish_post = $admin
      || ( $perms && $perms->can_publish_post )
      ? 1 : 0;
    my $create_post = $admin
      || ( $perms && $perms->can_create_post )
      ? 1 : 0;
    my $manage_pages = $admin
      || ( $perms && $perms->can_manage_pages )
      ? 1 : 0;
    require PowerRevision::PowerRevision;
    unless ( $app->blog ) {
        require MT::Permission;
        my $permission = MT::Permission->load( { author_id=> $user->id,
                                                 permissions => { like => '%create_post%' }
                                               }
                                             );
        return $app->trans_error( 'Permission denied.' ) unless defined $permission;
    } else {
        if ( ( ! $manage_pages ) && ( ! $create_post ) && ( ! $publish_post ) && ( ! $edit_all_posts ) && ( ! $admin ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
    }
    if ( $app->param( 'saved_deleted' ) ) {
        if ( $app->param( 'offset' ) ) {
            my $return_url = $app->uri( mode => 'list_powerrevision',
                                        args => { 'blog_id' => $app->param( 'blog_id' ),
                                                  'saved_deleted' => 1,
                                            } );
            return $app->redirect( $return_url );
        }
    }
    my %blogs; my $website; my @blog_ids;
    if ( $app->blog ) {
        if ( $app->blog->class ne 'blog' ) {
            $website = 1;
        }
    }
    if (! defined $app->blog ) {
        my @all_blogs = MT::Blog->load( { class => '*' } );
        for my $blog ( @all_blogs ) {
            $blogs{ $blog->id } = $blog;
        }
    }
    if ( $website ) {
        my @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
        $blogs{ $app->blog->id } = $app->blog;
        push ( @blog_ids, $app->blog->id );
        for my $blog ( @all_blogs ) {
            $blogs{ $blog->id } = $blog;
            push ( @blog_ids, $blog->id );
        }
    }
    my @author_loop; my @authors;
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column eq 'comment' ) {
                $val = substr_text( $val, 0, 40 ) . ( length_text( $val ) > 40 ? "..." : "" );
            }
            if ( $column eq 'object_name' ) {
                $val = substr_text( $val, 0, 30 ) . ( length_text( $val ) > 30 ? "..." : "" );
            }
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085; %H:%M:%S", $val, undef, $app->user ? $app->user->preferred_language : undef );
            }
            $row->{ $column } = $val;
        }
        my $original = $obj->original;
        if ( defined $original ) {
            $row->{ 'entry_status' } = $obj->original->status;
        } else {
            $row->{ 'entry_status' } = 0;
        }
        my $author = $obj->author;
        $row->{ 'author_name' } = $author->name;
        my $aid = $author->id;
        if ( $aid ) {
            unless ( grep ( /^$aid$/, @authors ) ) {
                push ( @authors, $aid );
                push ( @author_loop, { author_name => $author->name, author_id => $aid } );
            }
        }
        if ( ( $publish_post && $edit_all_posts ) || ( $admin ) ) {
            $row->{ 'can_recover' } = 1;
            $row->{ 'can_edit_entry' } = 1;
            $row->{ 'can_edit_revision' } = 1;
        } else {
            if ( ( $edit_all_posts ) || ( $user->id == $obj->author_id ) ) {
                $row->{ 'can_edit_entry' } = 1;
                if ( $obj->status == 1 ) {
                    $row->{ 'can_edit_revision' } = 1;
                }
                unless ( $publish_post ) {
                    if ( defined $original ) {
                        if ( $original->status != MT::Entry->HOLD() ) {
                            $row->{ 'can_edit_entry' } = 0;
                        } else {
                            if ( ( $edit_all_posts ) || ( $user->id == $original->author_id ) ) {
                                $row->{ 'can_edit_entry' } = 1;
                                $row->{ 'can_recover' } = 1;
                            }
                        }
                    } else {
                        $row->{ 'can_edit_entry' } = 0;
                        $row->{ 'can_recover' } = 1;
                    }
                } else {
                    $row->{ 'can_edit_revision' } = 1;
                }
            }
        }
        $row->{ can_edit_revision } = PowerRevision::Util::if_user_can_revision( $obj, $user, 'edit_revision' );
        if ( (! defined $app->blog ) || ( $website ) ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
                $row->{ 'blog_name' } = $blog_name;
            }
        }
    };
    my %terms;
    my %param;
    $terms{ 'object_ds' } = 'entry';
    if ( $website ) {
        $terms{ 'blog_id' } = \@blog_ids
    }
    #$app->config( 'TemplatePath', File::Spec->catdir( $plugin->path, 'tmpl' ) );
    $app->{ 'plugin_template_path' } = File::Spec->catdir( $plugin->path, 'tmpl' );
    $param{ 'list_id' } = 'powerrevision';
    $param{ 'system_view' } = 1 unless $app->param( 'blog_id' );
    $param{ 'LIST_NONCRON' } = 1;
    $param{ 'search_label' } = $plugin->translate( 'Revision' );
    $param{ 'saved_changes' } = 1 if $app->param( 'saved_changes' );
    $param{ 'not_changes' } = 1 if $app->param( 'not_changes' );
    $param{ 'not_diff' } = 1 if $app->param( 'not_diff' );
    $param{ 'saved_deleted' } = 1 if $app->param( 'saved_deleted' );
    $param{ 'saved' } = 1 if $app->param( 'saved' );
    $param{ 'dialog' } = 1 if $app->param( 'dialog' );
    if ( my $object_class = $app->param( 'object_class' ) ) {
        $param{ 'object_class' } = $object_class;
    }
    $param{ 'author_loop' } = \@author_loop;
    my $class_type = $app->param( 'class_type' );
    $terms{ 'class' } = $class_type if $class_type;
    return $app->listing (
        {
            type   => 'powerrevision',
            code   => $code,
            args   => { sort => 'modified_on', direction => 'descend' },
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub _cb_cms_pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $terms = $load_options->{ terms } || {};
    _remove_hash( 'author_id', $terms );
}

sub _remove_hash {
    my ( $key, $items ) = @_;
    if ( ref $items eq 'ARRAY' ) {
        for my $item ( @$items ) {
            if ( ref $item eq 'ARRAY' ) {
                _remove_hash( $key, $item );
            } elsif ( ref $item eq 'HASH' ) {
                delete $$item{ $key };
            }
        }
    } elsif ( ref $items eq 'HASH' ) {
        delete $$items{ $key };
    }
}

sub _cb_cms_pre_load_filtered_list_powerrevision {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $terms = $load_options->{ terms } || {};
    my $permitted_blog_ids = permitted_blog_ids( $app,
                                                  [ 'administer_blog',
                                                    'edit_all_posts',
                                                    'publish_post',
                                                    'create_post',
                                                    'manage_pages',
                                                  ],
                                               );
    $terms->{ blog_id } = $permitted_blog_ids;
}

sub _cb_ts_header {
    my ( $cb, $app, $tmpl ) = @_;
    if ( $app->mode eq 'list' ) {
        my $class = $app->param( '_type' );
        if ( $class && $class =~ /^(?:entry|page)$/ ) {
            my $insert =<<'MTML';
<link rel="stylesheet" href="<$mt:var name="static_uri"$>plugins/PowerRevision/css/list_entry.css" type="text/css" />
MTML
            my $search = quotemeta( '</head>' );
            $$tmpl =~ s/($search)/$insert$1/;
        }
        if ( $class && $class eq 'powerrevision' ) {
            my $insert =<<'MTML';
<link rel="stylesheet" href="<$mt:var name="static_uri"$>plugins/PowerRevision/css/list_powerrevision.css" type="text/css" />
MTML
            my $search = quotemeta( '</head>' );
            $$tmpl =~ s/($search)/$insert$1/;
        }
    }
    if ( $app->mode eq 'view' ) {
        my $class = $app->param( '_type' );
        if ( $class && $class =~ /^(?:entry|page)$/ ) {
            my $insert =<<'MTML';
<link rel="stylesheet" href="<$mt:var name="static_uri"$>plugins/PowerRevision/css/edit_entry.css" type="text/css" />
MTML
            my $search = quotemeta( '</head>' );
            $$tmpl =~ s/($search)/$insert$1/;
        }
    }
}

sub _cb_pre_run {
    my ( $cb, $app ) = @_;
    if ( $app->param( 'search_result' ) &&
         ( $app->param( '_type' ) && $app->param( '_type' ) eq 'powerrevision' )
    ) {
        return $app->redirect( $app->base . $app->uri( mode => 'list',
                                                       args => { _type => 'powerrevision',
                                                                 blog_id => $app->param( 'blog_id' ),
                                                                 filter_val => $app->param( 'id' ), 
                                                                 filter => 'id',
                                                               },
                                                     )
                             );
    }
    if ( $app->mode eq 'view' &&
         ( $app->param( '_type' ) && $app->param( '_type' ) =~ /^(?:entry|page)$/ )
    ) {
        if ( my $id = $app->param( 'id' ) ) {
            if ( $id < 0 && ! $app->param( 'edit_revision' ) ) {
                return $app->redirect( $app->base . $app->uri( mode => 'list',
                                                               args => { _type => 'powerrevision',
                                                                         blog_id => $app->param( 'blog_id' ),
                                                                         saved_changed => 1,
                                                                       },
                                                             )
                                     );
            }
        }
    }
    # preview
    if ( $app->mode eq 'preview_entry' ) {
        if ( my $orig_id = $app->param( 'orig_id' ) ) {
            my $orig_entry = MT->model( 'entry' )->load( { id => $orig_id } );
            $app->param( 'basename', $orig_entry->basename );
        }
    }
}

1;
