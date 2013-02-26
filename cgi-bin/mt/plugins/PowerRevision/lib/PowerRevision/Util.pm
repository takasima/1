package PowerRevision::Util;
use strict;

use File::Copy::Recursive qw( fcopy );

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( powercms_files_dir is_user_can build_tmpl make_dir 
                       site_path site_url current_user current_blog current_ts
                       permitted_blog_ids is_windows
                     );
use MT::Util qw( perl_sha1_digest_hex encode_xml encode_html );

use PowerRevision::Plugin;

sub has_list_permission { # TODO: test workflow/only has magage_pages
    my ( $class ) = @_;
    my $app = MT->instance();
    my @permitted_blog_ids;
    if ( $class && $class eq 'page' ) {
        @permitted_blog_ids = permitted_blog_ids( $app,
                                                  [ 'administer_blog',
                                                    'manage_pages',
                                                  ],
                                                );
    } else {
        @permitted_blog_ids = permitted_blog_ids( $app,
                                                  [ 'administer_blog',
                                                    'edit_all_posts',
                                                    'publish_post',
                                                    'create_post',
                                                    'manage_pages',
                                                  ],
                                                 );
    }
    return scalar @permitted_blog_ids;
}

sub change_status {
    my ( $app, $blog, $is_task ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $ts = current_ts( $blog );
    my @revision;
    if ( $is_task ) {
        $app = MT->instance();
        @revision = MT->model( 'powerrevision' )->load( { blog_id => $blog->id,
                                                          class => 'workflow', 
                                                          status => 4, 
                                                        }, {
                                                          'sort' => 'obj_auth_on',
                                                          start_val => $ts,
                                                          direction => 'descend',
                                                        } 
                                                      );
    } else {
        my @entries = $app->param( 'id' );
        for my $id( @entries ) {
            my $entry = MT::Entry->load( { id => $id } );
            next unless defined $entry;
            my @rev = MT->model( 'powerrevision' )->load( { blog_id => $blog->id, 
                                                            object_ds => 'entry',
                                                            object_id => $id,
                                                            class => 'workflow',
                                                          }, { 
                                                            'sort' => 'obj_auth_on',
                                                            limit => 1,
                                                            direction => 'ascend',
                                                          }
                                                        );
            push ( @revision, @rev );
        }
    }
    my %posted;
    for my $rev( @revision ) {
        $posted{ $rev->object_id } = $rev;
    }
    my $published;
    require MT::WeblogPublisher;
    my $pub = MT::WeblogPublisher->new();
    my $fmgr = MT::FileMgr->new( 'Local' );
    for my $entry_id( keys %posted ) {
        my $revision = $posted{ $entry_id };
        my $entry = MT::Entry->load( { id => $entry_id } );
        if ( $entry->class eq 'page' ) {
            $entry = MT->model( 'page' )->load( { id => $entry_id } );
        }
        my $original = $entry->clone_all();
        my $xml; my $backup_revision; my $backup_revision_id;
        my $backup_dir = PowerRevision::Util::backup_dir();
        my $xmlfile = File::Spec->catdir( $backup_dir, $revision->id . '.xml' );
        if ( $fmgr->exists( $xmlfile ) ) {
            $xml = $fmgr->get_data( $xmlfile );
            my $latest = MT->model( 'powerrevision' )->load( { object_id => $entry_id,
                                                               object_ds => 'entry' 
                                                             }, { 
                                                               'sort' => 'modified_on',
                                                               direction => 'descend',
                                                               limit => 1,
                                                             }
                                                           );
            if ( defined $latest ) {
                $backup_revision_id = $latest->id;
            }
            my %removes;
            if ( $revision->object_status == 1 ) {
                $revision->object_status( 2 );
                $revision->save or die $revision->errstr;
            }
            $revision->future_post( 0 );
            ( $entry, %removes ) = recover_entry_from_xml( $app, $blog, $entry, $revision, $xml, 0, 1, $backup_dir );
            $entry->status( MT::Entry::RELEASE() );
            MT->run_callbacks( 'cms_post_recover.' . ( $entry->class eq 'entry' ? 'entries' : 'pages' ), $app, $entry, $revision );
            $entry->save or die $entry->errstr;
            MT->run_callbacks( 'cms_post_recover_from_revision.' . $entry->class, $app, $entry, $original, $revision );
            $revision->class( 'backup' );
            $revision->status( MT::Entry::HOLD() );
            $revision->future_post( 0 );
            $revision->object_status( 2 );
            $revision->save or die $revision->errstr;
            my $builddependencies = 0;
            $pub->rebuild_entry( Entry => $entry, 
                                 BuildDependencies => ( $entry->class eq 'entry' ? 1 : 0 ),
                                 NoIndexes => 1 
                               ) or $app->error( $plugin->translate( 'Rebuild error: [_1]', $pub->errstr ) );
            $published = 1;
        }
    }
    if ( $published ) {
        $pub->rebuild_indexes( Blog => $blog )
            or $app->error( $plugin->translate( 'Rebuild error: [_1]', $pub->errstr ) );
    }
    return $published;
}

sub cleanup_assets {
    my $app = MT->instance();
    my $plugin = MT->component( 'PowerRevision' );
    my $limit;
    if ( my $user = current_user() ){
        $limit = 10;
    } else { # is task
        $limit = 999;
    }
    my $blog = current_blog( $app ); # if is task, 'current_blog' return undef.
    my @temp_files = MT::Session->load( { kind => 'TF',
                                          ( $blog ? ( blog_id => $blog->id ) : () ),
                                          class => ( $plugin->key || lc ( $plugin->id ) ),
                                        }, { 
                                          'sort' => 'start',
                                          start_val => ( time - 10 ),
                                          direction => 'descend',
                                          limit => $limit,
                                        },
                                      );
    return unless @temp_files;
    return remove_revision_temporary_files( \@temp_files );
}

sub remove_revision_temporary_files {
    my ( $temp_files ) = @_;
    return unless $temp_files;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my $remove_count = 0;
    for my $temp_file ( @$temp_files ) {
        my $path = $temp_file->name or next;
        if ( $fmgr->exists( $path ) ) {
            my @stat = stat( $path );
            my $size = $stat[ 7 ];
            my $modified = $stat[ 9 ];
            if ( ( $temp_file->modified && $temp_file->modified eq $modified ) &&
                 ( $temp_file->size && $temp_file->size eq $size )
               )
            {
                $fmgr->delete( $path );
            }
        }
        $temp_file->remove or die $temp_file->errstr;
        $remove_count++;
    }
    return $remove_count;
}

sub has_revision_permission {
    my ( $author, $blog ) = @_;
    return 0 unless $author;
#    return 0 unless $blog;
    unless ( ref $author eq 'MT::Author' ) {
        if ( $author =~ /^[0-9]$/ ) {
            $author = MT->model( 'author' )->load( { id => $author } );
        }
    }
    if ( ! ( ref $blog eq 'MT::WebSite' ) && ! ( ref $blog eq 'MT::Blog' ) ) {
        if ( $blog =~ /^[0-9]$/ ) {
            $blog = MT::Blog->load( { id => $blog } );
        }
    }
    my $admin = $author->is_superuser || ( $blog && is_user_can( $blog, $author, 'administer_blog' ) );
    my $edit_all_posts = is_user_can( $blog, $author, 'edit_all_posts' );
    my $publish_post = is_user_can( $blog, $author, 'publish_post' );
    my $create_post = is_user_can( $blog, $author, 'create_post' );
    my $manage_pages = is_user_can( $blog, $author, 'manage_pages' );
    if ( $admin || $edit_all_posts || $publish_post || $create_post || $manage_pages ) {
        return 1;
    }
    return 0;
}

sub backup_dir {
    my $powercms_files_dir = powercms_files_dir() or die;
    my $backup_dir = File::Spec->catdir( $powercms_files_dir, 'backup' );
    make_dir( $backup_dir );
    if ( -d $backup_dir ) {
        return $backup_dir;
    }
}

sub can_revision_update {
    my $app = MT->instance();
    my $user  = $app->user;
    my $blog = $app->blog;
    my $admin = $user->is_superuser || ( $blog && is_user_can( $blog, $user, 'administer_blog' ) );
    return 1 if $admin;
    my $edit_all_posts = is_user_can( $blog, $user, 'edit_all_posts' );
    my $publish_post = is_user_can( $blog, $user, 'publish_post' );
    unless ( $blog ) {
        require MT::Permission;
        my $permission = MT::Permission->load( { author_id => $user->id,
                                                 permissions => { like => '%publish_post%' },
                                               }
                                             );
        return 1 if defined $permission;
    }
    if ( $publish_post && $edit_all_posts ) {
        return 1;
    }
    return 0;
}

sub set_publishcharset {
    my $data = shift;
    my $enc = MT->config->PublishCharset;
    unless ( $enc =~ /^utf-?8$/i ) {
        return MT::I18N::encode_text( $data, 'utf8', lc( $enc ) );
    }
    return $data;
}

sub preview_object_basename {
    my $app = shift;
    my @parts;
    my $blog = $app->blog;
    my $blog_id = $blog->id if $blog;
    my $id = $app->param( 'id' );
    push @parts, $blog_id || 0;
    push @parts, $id || 0;
    push @parts, $app->param( '_type' );
    push @parts, $app->config->SecretToken;
    my $data = join ",", @parts;
    return 'mt-preview-' . perl_sha1_digest_hex( $data );
}

sub _build_tmpl {
    my ( $template, $at, $entry, $blog, $category, $app ) = @_;
    my %args = ( blog => $blog,
                 entry => $entry,
                 category => $category,
                );
    my %params;
    if ( my $archiver = MT->publisher->archiver( $at ) ) {
        if ( my $tmpl_param = $archiver->template_params ) {
            %params = %$tmpl_param;
        }
    }
    $params{ entry_template } = 1 if $at eq 'Individual';
    $params{ page_template } = 1 if $at eq 'Page';
    $params{ preview_template } = 1;
    return build_tmpl( $app, $template, \%args, \%params );
}

sub if_user_can_revision {
    my ( $obj, $author, $permission_text ) = @_;
    return 0 unless $obj;
    return 0 unless $author;
    return 0 unless $permission_text;
    unless ( $permission_text =~ /^can_/ ) {
        $permission_text = 'can_' . $permission_text;
    }
    unless ( $permission_text =~ /^(can_recover|can_edit_entry|can_edit_revision)$/ ) {
        return 0;
    }
    my $original = $obj->original();
    if ( $permission_text eq 'can_edit_entry' ) {
        return can_edit_entry( $obj->original(), $author )
    }
    my $blog = $obj->blog or return 0;
    my $admin = $author->is_superuser || is_user_can( $blog, $author, 'administer_blog' );
    my $publish_post = is_user_can( $blog, $author, 'publish_post' );
    my $edit_all_posts = is_user_can( $blog, $author, 'edit_all_posts' );
    if ( ( $publish_post && $edit_all_posts ) || $admin ) {
        return 1;
    } else {
        unless ( $admin ) {
            if ( $permission_text eq 'can_edit_revision' &&
                 $obj->class eq 'workflow' &&
                 $obj->status eq MT::Entry::HOLD() &&
                 $obj->author_id ne $author->id
            ) {
                return 0;
            }
        }
        if ( $edit_all_posts || ( $author->id == $obj->author_id ) ) {
            if ( $obj->status == MT::Entry::HOLD() ) {
                return 1 if $permission_text eq 'can_edit_revision';
            }
            unless ( $publish_post ) {
                if ( defined $original ) {
                    if ( $original->status != MT::Entry->HOLD() ) {
#                         return 0 if $permission_text eq 'can_edit_entry';
                    } else {
                        if ( ( $edit_all_posts ) || ( $author->id == $original->author_id ) ) {
                            return 1 if $permission_text eq 'can_recover';
                        }
                    }
                } else {
                    return 1 if $permission_text eq 'can_recover';
                }
            } else {
                return 1 if $permission_text eq 'can_edit_revision';
            }
        }
    }
    return 0;
}

sub can_edit_entry {
    my ( $entry, $author ) = @_;
    if ( MT->component( 'EntryWorkflow' ) ) {
        require EntryWorkflow::Util;
        return EntryWorkflow::Util::can_edit_entry( $entry, $author );
    }
    return 0 unless $entry;
    return 0 unless $author;
    my $blog = $entry->blog or return 0;
    my $admin = $author->is_superuser || is_user_can( $blog, $author, 'administer_blog' );
    my $publish_post = is_user_can( $blog, $author, 'publish_post' );
    my $edit_all_posts = is_user_can( $blog, $author, 'edit_all_posts' );
    if ( ( $publish_post && $edit_all_posts ) || $admin ) {
        return 1;
    } else {
        if ( $publish_post ) {
            if ( $author->id == $entry->author_id ) {
                return 1;
            }
        } else {
            if ( $entry->status == MT::Entry->HOLD() ) {
                if ( ( $edit_all_posts ) || ( $author->id == $entry->author_id ) ) {
                    return 1;
                }
            }
        }
    }
    return 0;
}

sub is_user_can_revision { goto &if_user_can_revision }

sub can_create_revision {
    my ( $author, $entry ) = @_;
    my $blog = $entry->blog;
    my $class = $entry->class;
    return 0 unless $author;
    return 0 unless $blog;
    return 0 unless $class;
    unless ( ref $author eq 'MT::Author' ) {
        if ( $author =~ /^[0-9]+$/ ) {
            $author = MT->model( 'author' )->load( { id => $author } );
        }
    }
    if ( ! ( ref $blog eq 'MT::WebSite' ) && ! ( ref $blog eq 'MT::Blog' ) ) {
        if ( $blog =~ /^[0-9]+$/ ) {
            $blog = MT::Blog->load( { id => $blog } );
        }
    }
    my $admin = $author->is_superuser || ( $blog && is_user_can( $blog, $author, 'administer_blog' ) );
    my $edit_all_posts = is_user_can( $blog, $author, 'edit_all_posts' );
    my $publish_post = is_user_can( $blog, $author, 'publish_post' );
    my $create_post = is_user_can( $blog, $author, 'create_post' );
    my $manage_pages = is_user_can( $blog, $author, 'manage_pages' );
    if ( $admin ) {
        return 1;
    }
    if ( $class eq 'entry' ) {
        if ( $edit_all_posts ) {
            return 1;
        }
    } else {
        if ( $manage_pages && $edit_all_posts ) {
            return 1;
        }
    }
    if ( $author->id == $entry->author_id ) {
        return 1;
    }
    return 0;
}

sub build_entry_xml {
    my $entry = shift;
    my $app = MT->instance();
    my $entry_id = $entry->id;
    my $blog_id = $entry->blog_id;
    my $blog = $entry->blog;
    if ( $entry->has_column( 'template_module_id' ) && ! $entry->template_module_id ) {
        $entry->template_module_id( undef );
    }
    unless ( $entry->modified_by ) {
        if ( current_user( $app ) ) {
            $entry->modified_by( $app->user->id );
        }
    }
    my $site_path = site_path( $blog );
    my $entry_column_names = $entry->column_names;
    my $res = "<powercms xmlns='http://alfasado.net/power_cms/ns/'>\n";
    $res .= "<mtentry>\n";
    for my $name ( @$entry_column_names ) {
        if ( ( $name ne 'modified_on' ) && ( $name ne 'status' ) && ( $name ne 'revision_comment' ) ) {
            if ( $name eq 'id' ) {
                $res .= "<entry_$name>" . encode_xml( abs ( $entry->$name ) ) . "</entry_$name>\n";
            } else {
                $res .= "<entry_$name>" . encode_xml( $entry->$name ) . "</entry_$name>\n";
            }
        }
    }
    $res .= "</mtentry>\n";
    $entry->clear_cache( 'categories' );
    $entry->clear_cache( 'category' );
    my $cats = $entry->categories;
    if ( my $primary = $entry->category ) {
        $res .= "<mtplacement>\n";
        for my $c ( @$cats ) {
            next unless defined $c;
            if ( $c->id == $primary->id ) {
                $res .= '<primary_id>' . $c->id . "</primary_id>\n";
            } else {
                $res .= '<placement_id>' . $c->id . "</placement_id>\n";
            }
        }
        $res .= "</mtplacement>\n";
    }
    $res .= "<mtobjecttag>\n";
    my @tags = MT->model( 'objecttag' )->load( { object_id => $entry_id,
                                                 object_datasource => 'entry',
                                               }
                                             );
    for my $tag ( @tags ) {
        my $names = $tag->column_names;
        $res .= "<objecttagdata>\n";
        for my $name ( @$names ) {
            if ( $name eq 'object_id' ) {
                $res .= "<objecttag_$name>" . encode_xml( abs ( $tag->$name ) ) . "</objecttag_$name>\n";
            } else {
                $res .= "<objecttag_$name>" . encode_xml( $tag->$name ) . "</objecttag_$name>\n";
            }
        }
        $res .= "</objecttagdata>\n";
    }
    $res .= "</mtobjecttag>\n";
    $res .= "<mtentrytags>";
    @tags = $entry->tags;
    my $tag_str = join( ',', @tags );
    $res .= $tag_str;
    $res .= "</mtentrytags>\n";
    $res .= "<mtobjectasset>\n";
    my @objassets = MT->model( 'objectasset' )->load( { object_id => $entry_id,
                                                        object_ds => 'entry',
                                                      }
                                                    );
    for my $objasset ( @objassets ) {
        my $names = $objasset->column_names;
        $res .= "<objectassetdata>\n";
        for my $name ( @$names ) {
            if ( $name eq 'object_id' ) {
                $res .= "<objectasset_$name>" . encode_xml( abs ( $objasset->$name ) ) . "</objectasset_$name>\n";
            } else {
                $res .= "<objectasset_$name>" . encode_xml( $objasset->$name ) . "</objectasset_$name>\n";
            }
        }
        $res .= "</objectassetdata>\n";
    }
    $res .= "</mtobjectasset>\n";
    $res .= "<mtentryasset>\n";
    my @assets;
    if ( scalar @objassets ) {
        $site_path =~ s!/$!! unless $site_path eq '/';
        $site_path = quotemeta( $site_path );
        my $site_url = site_url( $blog );
        @assets = MT->model( 'asset' )->load( { class => '*' },
                                              { join => MT::ObjectAsset->join_on( 'asset_id',
                                                                                  { object_ds => 'entry',
                                                                                    object_id => $entry_id,
                                                                                  },
                                                                                )
                                              },
                                            );
        for my $asset ( @assets ) {
            my $names = $asset->column_names;
            $res .= "<entryassetdata>\n";
            for my $name ( @$names ) {
                my $val = $asset->$name;
                if ( $name eq 'file_path' ) {
                    $val =~ s/^$site_path/%r/;
                } elsif ( $name eq 'url' ) {
                    $val =~ s/^$site_url/%r/;
                }
                $res .= "<entryasset_$name>" . encode_xml( $val ) . "</entryasset_$name>\n";
            }
            $res .= "</entryassetdata>\n";
        }
    }
    $res .= "</mtentryasset>\n";
    eval { require CustomFields::Util };
    unless ( $@ ){
        use CustomFields::Util qw( get_meta );
        # For Snippet Field
        my @fields = MT->model( 'field' )->load( { type => 'snippet', blog_id => [ 0, $blog_id ] } );
        my @snippet;
        for my $field ( @fields ) {
            push ( @snippet, $field->basename );
        }
        my $meta = get_meta( $entry );
        $res .= "<mtcustomfield>\n";
        for my $basename ( keys %$meta ) {
            if ( grep ( /^$basename$/, @snippet ) ) {
                my $data = $meta->{ $basename };
                if (! ref $data ) {
                    require MT::Serialize;
                    $data = MT::Serialize->unserialize( $data );
                }
                my $params = $data;
                my $tmp_res = '';
                for my $key ( keys %$params ) {
#                    my $tmp = encode_xml( $params->{ $key } );
#                    $tmp_res .= "<$key>" . $tmp . "</$key>\n";
                    if ( ( ref $params->{ $key } ) eq 'ARRAY' ) {
                        my $items = $params->{ $key };
                        for my $item ( @$items ) {
                            my $tmp = encode_xml( $item );
                            $tmp_res .= "<$key>" . $tmp . "</$key>\n";
                        }
                    } else {
                        my $tmp = encode_xml( $params->{ $key } );
                        $tmp_res .= "<$key>" . $tmp . "</$key>\n";
                    }
                }
                $res .= "<customfield_$basename>" . $tmp_res . "</customfield_$basename>\n";
            } else {
                $res .= "<customfield_$basename>" . encode_xml( $meta->{ $basename } ) . "</customfield_$basename>\n";
            }
        }
        # / For Snippet Field
        $res .= "</mtcustomfield>\n";
    }
    eval { require ExtFields::Extfields };
    unless ( $@ ){
        $res .= "<mtextfields>\n";
        my @fields = ExtFields::Extfields->load( { entry_id => $entry_id } );
        for my $field ( @fields ) {
            my $names = $field->column_names;
            $res .= "<extfieldsdata>\n";
            for my $name ( @$names ) {
                if ( $name eq 'entry_id' ) {
                    $res .= "<extfields_$name>" . encode_xml( abs ( $field->$name ) ) . "</extfields_$name>\n";
                } else {
                    $res .= "<extfields_$name>" . encode_xml( $field->$name ) . "</extfields_$name>\n";
                }
            }
            $res .= "</extfieldsdata>\n";
        }
        $res .= "</mtextfields>\n";
    }
    $res .= '</powercms>';
    unless ( MT->config->PublishCharset =~ /utf-?8/i ) {
         $res = to_utf8( $res );
    }
    return ( $res, \@assets );
}

sub recover_entry_from_xml {
    my ( $app, $blog, $entry, $revision, $xml, $rebuild, $save, $backup_dir ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    cleanup_assets();
    my @objassets = MT->model( 'objectasset' )->load( { object_id => $entry->id,
                                                        object_ds => 'entry',
                                                      }
                                                    );
    for my $objasset( @objassets ) {
        $objasset->remove or $objasset->errstr;
    }
    my $status;
    if (! defined $entry ) {
        $entry = MT::Entry->new;
        $status = 1;
    } else {
        $status = $entry->status;
    }
    my $blog_id = $blog->id; 
    my $entry_column_names = $entry->column_names;
    my $xmlsimple = XML::Simple->new(); 
    my $backup = $xmlsimple->XMLin( $xml );
    my $mtentry = $backup->{ mtentry };
    for my $name ( @$entry_column_names ) {
        if ( $name eq 'id' ) {
            if (! $entry->id ) {
                $entry->id( $mtentry->{ entry_id } );
            } else {
                $entry->id( $entry->id );
            }
        } elsif ( $name eq 'status' ) {
            $entry->status( $status );
        } elsif ( $name eq 'revision_comment' ) {
            $entry->revision_comment( $revision->comment );
        } elsif ( $name eq 'modified_on' ) {
            $entry->modified_on( $revision->modified_on );
        } else {
            my $val = $mtentry->{ 'entry_' . $name };
            eval {
                my $v = %$val;
            };
            unless ( $@ ) {
                if ( %$val == 0 ) {
                    $val = undef;
                }
            };
            if ( $val ) {
                $val = set_publishcharset( $val );
            }
            $entry->$name( $val );
        }
    }
    if (! $entry->author_id ) {
        $entry->author_id( $revision->author->id );
    }
    my $entry_author = MT->model( 'author' )->load( { id => $entry->author_id } );
    my $change_author;
    if (! $entry_author ) {
        $change_author = 1;
    } else {
        if (! is_user_can( $entry->blog, $entry_author, 'publish_post' ) ) {
            if ( $app->mode ne 'edit_revision' ) {
                $change_author = 1;
            }
        }
    }
    if ( $change_author ) {
        if ( my $user = current_user( $app ) ) {
            $entry->author_id( $user->id );
        } else {
            my $permission = ( $entry->class eq 'page' ? "\%'manage_pages'\%" : "\%'publish_post'\%" );
            my %args;
            $args{ join } = MT->model( 'permission' )->join_on( 'author_id',
                                                                { blog_id => $entry->blog_id,
                                                                  permissions => { like => $permission },
                                                                }
                                                              );
            $args{ limit } = 1;
            my $author = MT->model( 'author' )->load( undef, \%args );
            if ( $author ) {
                $entry->author_id( $author->id );
            }
        }
    }
    $app->run_callbacks( ( ref $app ) . '::post_recover_entry_from_xml.' . $entry->class, $app, \$entry, \$revision );
    $entry->save or die $entry->errstr;
    my $entry_id = $entry->id;
    my $mtplacement = $backup->{ mtplacement };
    my $primary_cat = $mtplacement->{ primary_id };
    my @cids;
    if ( $primary_cat ) {
        require MT::Category;
        my $category = MT::Category->count( $primary_cat );
        if ( $category ) {
            my $obj = MT->model( 'placement' )->get_by_key( { entry_id => $entry_id,
                                                              category_id => $primary_cat,
                                                              blog_id => $blog_id,
                                                            }
                                                          );
            $obj->is_primary( 1 ); 
            $obj->save or die $obj->errstr;
            push ( @cids, $obj->id );
            $entry->category( $obj );
        }
    }
    my @mt_placement_ids = $mtplacement->{ placement_id };
    my $placement_ids = $mtplacement->{ placement_id };
    eval { 
        @mt_placement_ids = @$placement_ids
    };
    for my $cid( @mt_placement_ids ) {
        next unless $cid;
        my $category = MT::Category->load( { id => $cid } );
        if ( defined $category ) {
            my $obj = MT->model( 'placement' )->get_by_key( { entry_id => $entry_id,
                                                              category_id => $cid,
                                                              blog_id => $blog_id,
                                                            }
                                                          );
            $obj->is_primary( 0 );
            $obj->save or die $obj->errstr;
            push ( @cids, $obj->id );
        }
    }
    my @places = MT->model( 'placement' )->load( { entry_id => $entry_id } );
    for my $place( @places ) {
        my $pid = $place->id;
        if (! grep ( /^$pid$/, @cids ) ) { 
            $place->remove or die $place->errstr;
        }
    }
    my @tids;
    my $mtobjecttag = $backup->{ mtobjecttag };
    my @mtobjecttagdatas = $mtobjecttag->{ objecttagdata };
    my $objecttagdatas = $mtobjecttag->{ objecttagdata };
    eval { @mtobjecttagdatas = @$objecttagdatas };
    for my $objecttag( @mtobjecttagdatas ) {
        my $oid = $objecttag->{ objecttag_tag_id } or next;
        my $tag = MT->model( 'tag' )->load( $oid );
        if ( defined $tag ) {
            my $obj = MT->model( 'objecttag' )->get_by_key( { object_id => $entry_id,
                                                              tag_id => $oid,
                                                              object_datasource => 'entry',
                                                              blog_id => $blog_id,
                                                            }
                                                          );
            $obj->save or die $obj->errstr; 
            push ( @tids, $obj->id );
        }
    }
    my @tags = MT->model( 'objecttag' )->load( { object_id => $entry_id, 
                                                 object_datasource => 'entry',
                                               }
                                             );
    for my $tag( @tags ) {
        my $tid = $tag->id; 
        if (! grep( /^$tid$/, @tids ) ) {
            $tag->remove or die $tag->errstr;
        }
    }
    my $mtentrytags = $backup->{ mtentrytags };
    eval { 
        my $v = %$mtentrytags;
    };
    unless ( $@ ){
        if ( %$mtentrytags == 0 ) {
            $mtentrytags = undef;
        }
    };
    if ( $mtentrytags ) {
        my @tags = split ( /,/, $mtentrytags );
        $entry->set_tags( @tags ); 
        $entry->save or die $entry->errstr;
    }
    eval {
        require CustomFields::BackupRestore;
        require CustomFields::Field;
    };
    unless ( $@ ){
        my $mtcustomfield = $backup->{ mtcustomfield };
        my $object_class = MT->model( $entry->class );
        my $class_type = $object_class->class_type || $object_class->datasource;
        my $iter = CustomFields::Field->load_iter( { blog_id => [ $entry->blog_id,
                                                                  0,
                                                                ],
                                                     obj_type => $class_type,
                                                   }
                                                 );
        my $fields;
        my @snippet_fields = MT->model( 'field' )->load( { type => 'snippet', blog_id => [ 0, $blog_id ] } );
        my @snippet;
        for my $field ( @snippet_fields ) {
            push ( @snippet, $field->basename );
        }
        while( my $field = $iter->() ) {
            my $basename = $field->basename;
            my $val = $mtcustomfield->{ "customfield_$basename" };
            eval { 
                my $v = %$val
            };
            unless ( $@ ) { 
                if ( %$val == 0 ) {
                    $val = undef;
                }
            };
            if ( grep ( /^$basename$/, @snippet ) ) {
#                 require MT::Serialize;
#                 my $ser = MT::Serialize->serialize( \$val );
#                 $fields->{ $basename } = $ser;
#                 $basename = 'field.' . $basename;
#                 $entry->$basename( $ser );
                $fields->{ $basename } = $val;
                $basename = 'field.' . $basename;
                $entry->$basename( $val );
            } else {
                $fields->{ $basename } = $val;
            }
        }
        CustomFields::BackupRestore::_update_meta( $entry, $fields );
    }
    my @aids;
    my $mtobjectasset = $backup->{ mtobjectasset };
    my @mtobjectassetdatas = $mtobjectasset->{ objectassetdata };
    my $objectassetdatas = $mtobjectasset->{ objectassetdata };
    eval { 
        @mtobjectassetdatas = @$objectassetdatas;
    };
    my %removes;
    for my $objectasset( @mtobjectassetdatas ) {
        my $oid = $objectasset->{ objectasset_asset_id } or next;
        my $asset = MT->model( 'asset' )->load( { id => $oid } );
        my $temporary_path;
        my $site_path = site_path( $blog );
        my $site_url = site_url( $blog );
        my $xml_file = File::Spec->catdir( $backup_dir, 'assets', $revision->id, $oid . '.xml' );
        my $fmgr = $blog->file_mgr;
        if ( $fmgr->exists( $xml_file ) ) {
            my $asset_xml = $fmgr->get_data( $xml_file );
            my $assetxmlspl = XML::Simple->new();
            my $asset_datas = $assetxmlspl->XMLin( $asset_xml );
            my $backuppath  = $asset_datas->{ backuppath };
            $backuppath =~ s/^%b/$backup_dir/;
            my $recover_asset; my $org_asset;
            if ( defined $asset ) {
                $org_asset = $asset->file_path;
                if ( $fmgr->exists( $org_asset ) ){
                    my @stats = stat ( $backuppath );
                    my $copy_modified = $stats[ 9 ]; 
                    my $copy_size = $stats[ 7 ];
                    my @orgstats = stat ( $org_asset );
                    my $org_modified = $orgstats[ 9 ];
                    my $org_size = $orgstats[ 7 ];
                    unless ( ( $copy_size == $org_size ) && ( $copy_modified == $org_modified ) ) {
                        $recover_asset = 1;
                    }
                } else {
                    $recover_asset = 1;
                }
            } else {
                $recover_asset = 1;
            }
            if (! defined $asset ) {
                $asset = MT->model( 'asset' )->new; 
            }
            my $asset_column_names = $asset->column_names;
            my $mtasset = $asset_datas->{ mtasset };
            for my $name( @$asset_column_names ) {
                my $val = $mtasset->{ 'asset_' . $name  };
                eval {
                    my $v = %$val;
                };
                unless ( $@ ) {
                    if ( %$val == 0 ) {
                        $val = undef;
                    }
                };
                if ( (! $save ) && ( $name eq 'id' ) ) {
                    $val = $val * -1;
                }
                if ( $val ) {
                    $val = PowerRevision::Util::set_publishcharset( $val );
                }
                $asset->$name( $val );
            }
            if ( ( $recover_asset ) || ( $entry_id < 0 ) ) {
                if (! $org_asset ) {
                    $org_asset = $asset->file_path;
                }
                my $original;
                if (! $save ) {
                    $original = $org_asset;
                    require File::Temp;
                    require File::Basename;
                    my $dir = File::Basename::dirname( $org_asset );
                    $fmgr->mkpath( $dir );
                    my ( $tmp_fh, $tmp_filename ) = File::Temp::tempfile( DIR => $dir,
                                                                          SUFFIX => '.' . $asset->file_ext,
                                                                        );
                    $org_asset = $tmp_filename;
                    $temporary_path = $org_asset;
                    my $asset_path = $temporary_path;
                    my ( $name, $path, $suffix ) = File::Basename::fileparse( $temporary_path, () );
                    $site_path = quotemeta( $site_path );
                    $asset_path =~ s/^$site_path/%r/;
                    $asset->file_path( $asset_path );
                    if ( is_windows() ) {
                        $asset_path =~ s!\\!/!g;
                    }
                    $asset->url( $asset_path );
                    $asset->file_name( $name );
                }
                fcopy( $backuppath, "$org_asset.new" );
                $fmgr->rename( "$org_asset.new", $org_asset );
                if (! $save ) {
                    my @t_stat = stat ( $org_asset );
                    my $t_size = $t_stat[ 7 ];
                    my $t_modified = $t_stat[ 9 ];
                    my $sess_obj = MT::Session->get_by_key( { kind => 'TF',
                                                              name => $org_asset,
                                                              blog_id => $blog->id,
                                                              entry_id => $entry_id,
                                                              modified => $t_modified,
                                                              size => $t_size,
                                                              class => ( $plugin->key || lc ( $plugin->id ) ),
                                                            }
                                                          );
                    $sess_obj->id( $app->make_magic_token() );
                    $sess_obj->start( time );
                    $sess_obj->save;
                }
                $asset->save or die $asset->errstr;
                push ( @aids, $asset->id );
                $removes{ $original } = $asset unless $save;
            }
        }
        if ( defined $asset ) {
            my $asset_id = $asset->id;
            my $obj = MT->model( 'objectasset' )->get_by_key( { object_id => $entry_id,
                                                                asset_id => $asset_id,
                                                                object_ds => 'entry',
                                                                blog_id => $blog_id,
                                                              }
                                                            );
            my $names = $obj->column_names;
            my $save_sel;
            for my $name( @$names ) {
                my $val = $objectasset->{ 'objectasset_' . $name };
                eval {
                    my $v = %$val
                }; 
                unless ( $@ ){
                    if ( %$val == 0 ) { 
                        $val = undef;
                    }
                };
                if ( (! $save ) && ( $name eq 'asset_id' ) ) {
                    $val = $asset_id;
                }
                $obj->$name( $val );
            }
            if ( $entry_id < 0 ) {
                $obj->id( undef ); 
                $obj->object_id( $entry->id );
            }
            $obj->save or die $obj->errstr;
        }
    }
    my @assets = MT->model( 'objectasset' )->load( { object_id => $entry_id, 
                                                     object_ds => 'entry',
                                                   }
                                                 );
    for my $asset( @assets ) {
        my $aid = $asset->asset_id;
        unless ( grep ( /^$aid$/, @aids ) ) {
            $asset->remove or die $asset->errstr;
        }
    }
    eval { 
        require ExtFields::Extfields;
    }; 
    unless ( $@ ){
        my @exids;
        my $mtextfields = $backup->{ mtextfields };
        my @mtextfieldsdatas = $mtextfields->{ extfieldsdata };
        my $extfieldsdatas = $mtextfields->{ extfieldsdata };
        eval { @mtextfieldsdatas = @$extfieldsdatas };
        for my $extfields( @mtextfieldsdatas ) {
            my $oid = $extfields->{ extfields_id };
            next unless $oid;
            my $obj;
            if ( $entry_id < 0 ) {
                $obj = ExtFields::Extfields->new;
                $obj->entry_id( $entry_id );
            } else {
                $obj = ExtFields::Extfields->get_by_key( { id => $oid,
                                                           entry_id => $entry_id,
                                                         }
                                                       );
            }
            my $names = $obj->column_names;
            for my $name( @$names ) {
                if ( $name ne 'entry_id' ) {
                    my $val = $extfields->{ "extfields_$name" };
                    eval { 
                        my $v = %$val;
                    };
                    unless ( $@ ){ 
                        if ( %$val == 0 ) {
                            $val = undef; 
                        }
                    };
                    $obj->$name( $val );
                }
            }
            if ( $entry_id < 0 ) {
                $obj->id( undef );
            }
            $obj->save or die $obj->errstr;
            push ( @exids, $obj->id );
        }
        my @fields = ExtFields::Extfields->load( { entry_id => $entry_id } );
        for my $field( @fields ) {
            my $fid = $field->id;
            unless ( grep ( /^$fid$/, @exids ) ) {
                $field->remove or die $field->errstr;
            }
        }
    }
    if ( ( $rebuild ) && ( $entry->status == MT::Entry::RELEASE() ) ) {
        require MT::WeblogPublisher;
        my $pub = MT::WeblogPublisher->new();
        $pub->rebuild_entry( Entry => $entry, BuildDependencies => 1, ) 
            or die ( 'Rebuild error: [_1]', $pub->errstr );
        if ( $entry->status != MT::Entry::RELEASE() ) {
            $pub->remove_entry_archive_file( Entry => $entry );
        }
    }
    my $object_name = encode_html( $revision->object_name );
    my $author_name = ''; 
    eval { 
        my $author = $app->user; 
        $author_name = $author->nickname || $author->name;
    };
    if ( $@ && ! $author_name ) {
        $author_name = MT->translate( 'Scheduled Tasks Update' );
    }
    my $revision_id = $revision->id;
    $entry_id = $revision->object_id;
    my $class = $revision->object_class;
    $class =~ s/(^.)/uc($1)/e;
    $class = $plugin->translate( $class );
    if ( $save == 1 ) {
        $app->log( $plugin->translate( '[_1] \'[_2]\' (ID:[_3]) recoverd from revision (ID:[_4]) by \'[_5]\'', $class, $object_name, $entry_id, $revision_id, $author_name ) );
    } elsif ( $save == 2 ) {
        $app->log( $plugin->translate( '[_1] saved \'[_2]\' (ID:[_3])\'s revision (ID:[_4]) by \'[_5]\'', $class, $object_name, $entry_id, $revision_id, $author_name ) );
    }
    $entry->clear_cache();
    return ( $entry, %removes );
}

1;