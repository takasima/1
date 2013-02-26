package PowerRevision::CMS;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( site_path site_url write2file is_windows is_user_can
                       current_user file_extension file_basename
                     );
use MT::Util qw( encode_html perl_sha1_digest_hex );

use PowerRevision::Util;
use PowerRevision::Plugin;

my $plugin = MT->component( 'PowerRevision' );

sub _mode_recover_entry {
    my $app = shift;
    my $revision_id = $app->param( 'revision_id' );
    my $entry_id = $app->param( 'entry_id' );
    my $blog_id = $app->param( 'blog_id' );
    my $rebuild = $app->param( 'rebuild' );
    my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
    unless ( defined $revision ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $entry_class = $app->param( '_type' );
    unless ( defined $entry_class ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $entry = MT->model( $entry_class )->load( { id => $entry_id } );
    if (! defined $entry ) {
        $entry = MT->model( $entry_class )->get_by_key( { id => $revision->object_id,
                                                          blog_id => $blog_id,
                                                          status => 1,
                                                          class => $revision->object_class
                                                        }
                                                      );
    }
    unless ( defined $entry ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $original = $entry->clone_all();
    my $user = current_user( $app );
    unless ( PowerRevision::Util::is_user_can_revision( $revision, $user, 'can_recover' ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $backup_dir = PowerRevision::Util::backup_dir();
    my $xmlfile = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
    my $fmgr = $app->blog->file_mgr;
    if ( $fmgr->exists( $xmlfile ) ) {
        my $xml = $fmgr->get_data( $xmlfile );
        if ( $entry->has_column( 'template_module_id' ) && ! $entry->template_module_id ) {
            $entry->template_module_id( undef );
        }
        my ( $current_xml, $asset ) = PowerRevision::Util::build_entry_xml( $entry );
        if ( $current_xml ne $xml ) {
            my $backup_revision_id;
            my $latest = MT->model( 'powerrevision' )->load( { object_id => $entry_id,
                                                               object_ds => 'entry',
                                                             }, {
                                                               'sort' => 'modified_on',
                                                               direction => 'descend',
                                                               limit => 1,
                                                             }
                                                           );
            if ( defined $latest ) {
                $backup_revision_id = $latest->id;
            }
            my $changed = 0;
            if ( $revision->object_status == 1 ) {
                $revision->object_status( 2 );
                $revision->future_post( 0 );
                $changed++;
            }
            if ( $revision->class eq 'workflow' ) {
                $revision->class( 'backup' );
                $revision->status( MT::Entry::HOLD() );
                $revision->author_id( $user->id );
                $changed++;
            }
            if ( $changed ) {
                $revision->save or die $revision->errstr;
            }
            ( $entry, my %removes ) = PowerRevision::Util::recover_entry_from_xml( $app, $app->blog, $entry, $revision, $xml, 0, 0, $backup_dir );
            MT->run_callbacks( 'cms_post_recover.' . $entry->class, $app, $entry, $revision );
            my $saved_changes;
            if ( $rebuild ) {
                $entry->status( MT::Entry::RELEASE() );
                $entry->save or die $entry->errstr;
                MT->run_callbacks( 'cms_post_recover_from_revision.' . $entry->class, $app, $entry, $original, $revision );
                MT::Util::start_background_task(
                    sub {
                            $app->rebuild_entry( Entry => $entry,
                                                 BuildDependencies => ( $entry->class eq 'entry' ? 1 : 0 ),
                                               );
                        }
                );
                $saved_changes = 1;
            }
            my $redirect_url = $app->base . $app->uri( mode => 'view',
                                                       args => { _type => $entry->class,
                                                                 id => $entry->id,
                                                                 blog_id => $entry->blog_id,
                                                                 recovered => 1,
                                                                 ( $revision_id != $backup_revision_id ? ( backup_revision_id => $backup_revision_id ) : () ),
                                                                 saved_changes => $saved_changes,
                                                               },
                                                     );
            return $app->redirect( $redirect_url );
        } else {
            my $redirect_url = $app->uri( mode => 'view',
                                          args => { _type => $entry->class,
                                                    id => $entry->id,
                                                    blog_id => $entry->blog_id,
                                                    not_recovered => 1,
                                                  },
                                        );
            return $app->redirect( $redirect_url );
        }
    } else {
        my $class = $entry->class;
        $class =~ s/(^.)/uc($1)/e;
        $app->log( $plugin->translate( '[_1] is not recovered from backup (XML file was not found).', encode_html( $plugin->translate( $class ) ) ) );
        my $redirect_url = $app->base . $app->uri( mode => 'view',
                                                   args => { _type => $entry->class,
                                                             id => $entry->id,
                                                             blog_id => $entry->blog_id,
                                                             no_xml => 1,
                                                           },
                                                 );
        return $app->redirect( $redirect_url );
    }
}

sub _mode_preview_history {
    my $app = MT->instance;
    my $blog = $app->blog or return $app->trans_error( 'Invalid request.' );
    my $blog_id = $blog->id;
    my $revision_id = $app->param( 'revision_id' ) or return $app->trans_error( 'Invalid request.' );
    my $entry_id = $app->param( 'entry_id' ) or return $app->trans_error( 'Invalid request.' );
    my $class = $app->param( '_type' ) or return $app->trans_error( 'Invalid request.' );
    my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
    unless ( defined $revision ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $user = $app->user;
    unless ( PowerRevision::Util::has_revision_permission( $user, $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $site_path = site_path( $blog );
    my $site_url = site_url( $blog );
    my $backup_dir = PowerRevision::Util::backup_dir();
    if ( is_windows() ) {
        unless ( $backup_dir eq '\\' ) {
            $backup_dir =~ s!\$!!;
        }
    }
    my $xmlfile = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
    my $fmgr = $app->blog->file_mgr;
    if ( $fmgr->exists( $xmlfile ) ) {
        my $xml = $fmgr->get_data( $xmlfile );
        my $at = $class eq 'page' ? 'Page' : 'Individual';
        my $entry = MT->model( $class )->new;
        $entry->id( $entry_id * -1 );
        $entry->status( 1 );
        require MT::TemplateMap; # neccesary
        my $template = MT->model( 'template' )->load( { blog_id => $blog_id },
                                                      { join => [ 'MT::TemplateMap',
                                                                  'template_id',
                                                                  { blog_id => $blog_id,
                                                                    archive_type => $at,
                                                                    is_preferred => 1,
                                                                  }, {
                                                                    unique => 1,
                                                                  }
                                                                ],
                                                      }
                                                   );
        unless ( defined $template ) {
            $app->trans_error( 'Can\'t load template.' );
        }
        my ( $build_entry, %removes ) = PowerRevision::Util::recover_entry_from_xml( $app, $app->blog, $entry, $revision, $xml, 0, 0, $backup_dir );
        $entry->save or die $entry->errstr;
        $entry = MT->model( $class )->load( $entry->id );
        my $html = PowerRevision::Util::_build_tmpl( $template->text, $at, $build_entry, $blog, $build_entry->category, $app );
        $entry->remove or die $entry->errstr;
        my $abs_path = $site_url;
        $abs_path =~ s/https*:\/\/.*?(\/.*$)/$1/;
        $abs_path = quotemeta( $abs_path );
        my $doc_root = $site_path;
        $doc_root =~ s/$abs_path$//;
        if ( $doc_root =~ /(.*)\/$/ ) {
            $doc_root = $1;
        }
        if ( is_windows() ) {
            if ( $doc_root =~ /(.*)\\$/ ) {
                $doc_root = $1;
            }
        }
        my $file = $entry->archive_file();
        $file = File::Spec->catfile( $site_path, $file );
        require File::Basename;
        my $dir = File::Basename::dirname( $file );
        my $match = '<[^>]+\s(src|href|action)\s*=\s*\"';
        my @org_asset;
        my @save_asset;
        $html =~ s/($match)(.{1,}?)(")/$1.PowerRevision::Plugin::_check_asset( $app, $blog, $entry, $3, $dir, $site_path, $site_url, $doc_root, 0, \@org_asset, \@save_asset ).$4/esg;
        my $entry_id = $entry->id;
        eval {
            require ExtFields::Extfields;
        };
        unless ( $@ ){
            my @fields = ExtFields::Extfields->load( { entry_id => $entry_id } );
            for my $field( @fields ) {
                $field->remove or die $field->errstr;
            }
        }
        $site_path = quotemeta( $site_path );
        for my $path( keys %removes ) {
            my $asset = $removes{ $path };
            $path =~ s/^$site_path/$site_url/;
            if ( is_windows() ) {
                $path =~ s!\\!/!g;
            }
            my $asset_url = $asset->url;
            $path = quotemeta( $path );
            $asset->file_path( undef );
            $asset->remove or die $asset->errstr;
            if ( $asset_url =~ /^$site_path/ ) {
                $asset_url =~ s/^$site_path/$site_url/;
            }
            $html =~ s/$path/$asset_url/g;
        }
        my $script_url = $app->base . $app->uri;
        my $cleanup_js = <<MTML;
<script type="text/javascript">
var counter = 0;
var cleanup_temporary_func_id;
function cleanup_temporary_func () {
    if ( counter != 0 ) {
        clearTimeout( cleanup_temporary_func_id );
        counter = 0;
    } else {
        counter = 1;
        cleanup_temporary_func_id = setTimeout( "cleanup_temporary_func ( cleanup_temporary_file () )", 2200 );
    }
}
cleanup_temporary_func();
function cleanup_temporary_file () {
    var cleanup_temporary_file_obj = new Image();
    cleanup_temporary_file_obj.src = "$script_url?__mode=cleanup_temporary&amp;entry_id=$entry_id&amp;blog_id=$blog_id";
}
</script>
MTML
        $html =~ s!</html>!$cleanup_js</html>!;
        my $preview_basename = PowerRevision::Util::preview_object_basename( $app );
        my $permalink = $entry->permalink;
        my $permalink_file_extension = file_extension( file_basename( $permalink ) ) || '';
#        $permalink =~ s!^(.*/).*$!$1$preview_basename$permalink_file_extension!;
        $permalink =~ s!^(.*/).*$!$1$preview_basename!;
        if ( $permalink_file_extension ) {
            $permalink .= '.' . $permalink_file_extension;
        }
        my $outfile_extension = file_extension( file_basename( $file ) ) || '';
#         $file =~ s!^(.*/).*$!$1$preview_basename$outfile_extension!;
#         if ( $file =~ m/\\/ ) {
#             $file =~ s!^(.*\\).*$!$1$preview_basename$outfile_extension!;
#         }
        $file =~ s!^(.*/).*$!$1$preview_basename!;
        if ( $file =~ m/\\/ ) {
            $file =~ s!^(.*\\).*$!$1$preview_basename!;
        }
        if ( $outfile_extension ) {
            $file .= '.' . $outfile_extension;
        }
        if (! write2file( $file, $html ) ) {
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
        my @stat = stat( $file );
        my $size = $stat[ 7 ];
        my $modified = $stat[ 9 ];
        $sess_obj->size( $size );
        $sess_obj->modified( $modified );
        $sess_obj->start( time );
        $sess_obj->save;
        $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
        my $tmplate = 'powerrevision_previewentry.tmpl';
        my %param;
        $param{ blog_name } = $blog->name;
        $param{ blog_id } = $blog->id;
        $param{ page_title } = $plugin->translate( 'Preview Entry' );
        $param{ tmpfile_id } = $sess_obj->id;
        $param{ publish_msg_value } = $class eq 'entry' ? $plugin->translate( 'Publish this Entry from this revision?' ) : $plugin->translate( 'Publish this Page from this revision?' );
        $param{ entry_id } = $entry->id;
        $param{ object_type } = $class;
        $param{ title } = $entry->title;
        $param{ preview_url } = $permalink;
        $param{ mode } = $app->mode;
        if ( $revision->has_column( 'owner_id' ) ) {
            if ( $revision->owner_id ) {
                $param{ owner_id } = $revision->owner_id;
            }
        }
        my $edit_uri = $app->base . $app->uri( mode => 'edit_revision',
                                               args => { _type => $class,
                                                         entry_id => abs( $entry_id ),
                                                         blog_id => $blog_id,
                                                         revision_id => $revision_id,
                                                       }
                                             );
        $param{ edit_uri } = $edit_uri;
        my $publish_uri = $app->base . $app->uri( mode => 'recover_entry',
                                                  args => { _type => $class,
                                                            entry_id => $entry_id,
                                                            blog_id => $blog_id,
                                                            revision_id => $revision_id,
                                                            rebuild => 1,
                                                          },
                                                );
        $param{ publish_uri } = $publish_uri;
        my $sendback_uri = $app->base . $app->uri( mode => 'sendback_dialog',
                                                   args => { _type => $class,
                                                             id => $entry_id,
                                                             revision_id => $revision_id,
                                                             blog_id => $blog_id,
                                                           }
                                                 );
        $param{ sendback_uri } = $sendback_uri;
        $param{ can_edit } = 1;
        my $publish_post = is_user_can( $blog, $user, 'publish_post' );
        if (! $publish_post ) {
            if ( $revision->status != 1 ) {
                $param{ can_edit } = 0;
            }
        }
        $param{ can_publish } = $publish_post;
        $param{ can_edit_revision } = PowerRevision::Util::if_user_can_revision( $revision, $user, 'edit_revision' );
        $param{ revision_class } = $revision->class;
        $param{ revision_status } = $revision->status;
        $param{ can_publish_post } = $publish_post;
        $param{ can_rebuild } = is_user_can( $blog, $user, 'rebuild' );
        return $app->build_page( $tmplate, \%param );
    } else {
        $app->trans_error( 'Invalid request.' );
    }
}

sub _mode_edit_revision {
    my $app = shift;
    my $revision_id = $app->param( 'revision_id' ) or return $app->trans_error( 'Invalid request.' );
    my $blog = $app->blog or return $app->trans_error( 'Invalid request.' );
    my $entry_id = $app->param( 'entry_id' ) or return $app->trans_error( 'Invalid request.' );
    my $class = $app->param( '_type' ) or return $app->trans_error( 'Invalid request.' );
    my $blog_id = $blog->id;
    my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
    unless ( defined $revision ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $perms = $app->permissions;
    my $user = $app->user;
    unless ( PowerRevision::Util::has_revision_permission( $user, $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $admin = $user->is_superuser || ( $blog && is_user_can( $blog, $user, 'administer_blog' ) );
    my $edit_all_posts = is_user_can( $blog, $user, 'edit_all_posts' );
    my $publish_post = is_user_can( $blog, $user, 'publish_post' );
    unless ( $edit_all_posts || $admin ) {
        if ( $user->id != $revision->author_id ) {
            return $app->trans_error( 'Permission denied.' );
        }
    }
    if (! $publish_post ) {
        if ( $revision->status != MT::Entry::HOLD() ) {
            return $app->trans_error( 'Permission denied.' );
        }
    }
    my $backup_dir = PowerRevision::Util::backup_dir();
    my $xmlfile = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
    my $fmgr = $app->blog->file_mgr;
    if ( $fmgr->exists( $xmlfile ) ) {
        my $xml = $fmgr->get_data( $xmlfile );
        my $entry = MT->model( $class )->new;
        my $at = 'Individual';
        if ( $class eq 'page' ) {
            $at = 'Page';
        }
        $entry->id ( $entry_id * -1 );
        $entry->status( MT::Entry::HOLD() );
        my ( $build_entry, %removes ) = PowerRevision::Util::recover_entry_from_xml( $app, $app->blog, $entry, $revision, $xml, 0, 2, $backup_dir );
        $entry = MT->model( $class )->load( $entry->id );
        $app->redirect( $app->uri( mode => 'view',
                                   args => { blog_id => $entry->blog_id,
                                             _type => $entry->class,
                                             id => $entry->id,
                                             edit_revision => 1,
                                             revision_id => $app->param( 'revision_id' ),
                                             ( $app->param( 'saved_changes' ) ? ( saved_changes => 1 ) : () ),
                                           }
                                 )
                      );
    } else {
        $app->trans_error( 'Invalid request.' );
    }
}

sub _mode_recover_entries {
    my $app = shift;
    if (! $app->validate_magic ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $blog = $app->blog or return $app->trans_error( 'Invalid request.' );
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @id = $app->param( 'id' ) or return $app->trans_error( 'Invalid request.' );
    my $user = $app->user;
    unless ( PowerRevision::Util::has_revision_permission( $user, $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    unless ( PowerRevision::Util::can_revision_update() ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $admin = $user->is_superuser || ( $blog && is_user_can( $blog, $user, 'administer_blog' ) );
    my $edit_all_posts = is_user_can( $blog, $user, 'edit_all_posts' );
    my $backup_dir = PowerRevision::Util::backup_dir();
    if ( is_windows() ) {
        unless ( $backup_dir eq '\\' ) {
            $backup_dir =~ s!\$!!;
        }
    }
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my @revisions; my @entry_ids; my @blog_ids;
    for my $revision_id( @id ) {
        my $revision = MT->model( 'powerrevision' )->load( { id => $revision_id } );
        if ( $revision->object_ds ne 'entry' ) {
            return $app->trans_error( 'Invalid request.' );
        }
        my $entry_id = $revision->object_id;
        if ( grep( /^$entry_id$/, @entry_ids ) ) {
            return $app->error( $plugin->translate( 'Can\'t recover same entry at a time.' ) );
        }
        my $xmlfile = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
        if (! $fmgr->exists( $xmlfile ) ) {
            return $app->error( $plugin->translate( 'XML file was not found.' ) );
        }
        unless ( ( $edit_all_posts ) || ( $admin ) ) {
            if ( $user->id != $revision->author_id ) {
                return $app->trans_error( 'Permission denied.' );
            }
        }
        push ( @revisions, $revision );
        push ( @entry_ids, $entry_id );
        my $revision_blog_id = $revision->blog_id;
        if (! grep ( /^$revision_blog_id$/, @blog_ids ) ) {
            push ( @blog_ids, $revision_blog_id );
        }
    }
    my %blogs;
    if (! $blog ) {
        for my $blog_id( @blog_ids ) {
            $blogs{ $blog_id } = MT::Blog->load( { id => $blog_id } );
        }
    }
    my $saved_changes;
    my $not_diff;
    for my $revision ( @revisions ) {
        my $xmlfile = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
        my $xml = $fmgr->get_data( $xmlfile );
        unless ( $blog ) {
            $blog = $blogs{ $revision->blog_id };
        }
        my $entry = MT::Entry->load( { id => $revision->object_id } );
        if ( $entry ) {
            my ( $current_xml, $asset ) = PowerRevision::Util::build_entry_xml( $entry );
            if ( $current_xml eq $xml ) {
                $not_diff = 1;
            }
            next if $not_diff;
        } else {
            $entry = MT::Entry->new;
            $entry->id( $revision->object_id );
            $entry->status( MT::Entry::HOLD() );
        }
        my $res = PowerRevision::Util::recover_entry_from_xml( $app, $blog, $entry, $revision, $xml, 0, 1, $backup_dir );
        if ( $revision->object_status != 2 ) {
            $revision->object_status( 2 );
            $revision->future_post( 0 );
            $revision->save or $revision->errstr;
            my @revs = MT->model( 'powerrevision' )->load( { id => { not => $revision->id },
                                                             object_id => $revision->object_id,
                                                             object_ds => 'entry',
                                                           }
                                                         );
            for my $rev( @revs ) {
                $rev->object_status( 2 );
                $rev->save or $rev->errstr;
            }
        }
        if (! $saved_changes ) {
            $app->add_return_arg( saved_changes => 1 );
            $saved_changes = 1;
        }
    }
    if (! $saved_changes ) {
        $app->add_return_arg( not_changes => 1 );
    }
    if ( $not_diff ) {
        $app->add_return_arg( not_diff => 1 );
    }
    $app->call_return;
}

sub _mode_cleanup_temporary {
    my $app = shift;
    my $user = $app->user;
    my $blog = $app->blog;
    unless ( PowerRevision::Util::has_revision_permission( $user, $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $entry_id = $app->param( 'entry_id' );
    my @temp_files = MT::Session->load( { kind => 'TF',
                                          blog_id => $blog->id,
                                          entry_id => $entry_id,
                                          class => ( $plugin->key || lc ( $plugin->id ) ),
                                        }
                                      );
    PowerRevision::Util::remove_revision_temporary_files( \@temp_files );
    return 'Cleanup temporary files!';
}

sub _action_revision_update {
    my $app = shift;
    unless ( PowerRevision::Util::can_revision_update() ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my @id = $app->param( 'id' ) or return $app->errtrans( 'Invalid request.' );
    my $published = PowerRevision::Util::change_status( $app, $app->blog, 0 );
    if ( $published ) {
        $app->add_return_arg( saved => 1 );
    } else {
        $app->add_return_arg( not_saved => 1 );
    }
    $app->call_return;
}

1;
