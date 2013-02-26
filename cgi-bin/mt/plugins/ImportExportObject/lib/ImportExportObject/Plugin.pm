package ImportExportObject::Plugin;

use strict;
use lib qw( addons/Commercial.pack/lib addons/PowerCMS.pack/lib );
use File::Temp qw( tempfile );
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use PowerCMS::Util qw( utf8_off current_ts upload utf8_on file_label save_asset
                       allow_upload csv_new plugin_template_path site_path get_all_blogs
                       uniq_filename path2relative association_link is_windows );
use MT::Util qw( trim );

sub _start_im_export {
    my $app = shift;
    my $blog_id = $app->param( 'blog_id' );
    return $app->trans_error( 'Permission denied.' ) if ! $app->user->is_superuser && ! $blog_id;
    return $app->trans_error( 'Permission denied.' ) if ! $app->can_do( 'administer_blog' );
    my $plugin = MT->component( 'ImportExportObject' );
    $app->{ plugin_template_path } = plugin_template_path( $plugin );
    my $tmpl = 'start_im_export.tmpl';
    my %param;
    $param{ saved } = $app->param( 'saved' );
    return $app->build_page( $tmpl, \%param );
}

sub _im_export_object {
    my $app = shift;
    my $user = $app->user;
    my $admin = $user->is_superuser;
    my $blog_id = $app->param( 'blog_id' );
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    return $app->trans_error( 'Permission denied.' ) if ! $user->is_superuser && ! $blog_id;
    if ( my $blog = $app->blog ) {
        if ( $blog->is_blog ) {
            return $app->trans_error( 'Permission denied.' ) if ! $app->can_do( 'administer_blog' );
        } else {
            return $app->trans_error( 'Permission denied.' ) if ! $app->can_do( 'administer_website' );
        }
    }
    if ( $app->param( 'action' ) eq 'import' ) {
        _import_object( $app );
    } else {
        _export_object( $app );
    }
}

sub _import_object {
    my $app = shift;
    require MT::Request;
    require MT::Asset;
    require MT::ObjectAsset;
    my $r = MT::Request->instance;
    my $plugin = MT->component( 'ImportExportObject' );
    my $blog = $app->blog;
    my $model = $app->param( '_type' );
    if (! $blog ) {
        if ( $model eq 'asset' ) {
            return $app->trans_error( 'Invalid request.' );
        }
        require MT::Blog;
        $blog = MT::Blog->load( { class => [ 'blog', 'website' ] }, { limit => 1 } );
    } else {
        if ( $model eq 'author' ) {
            return $app->trans_error( 'Invalid request.' );
        }
    }
    my $user = $app->user;
    my $do;
    my @models = ( 'author', 'entry', 'page', 'category', 'folder', 'asset', 'field' );
    if (! grep( /^$model$/, @models ) ) {
        return $app->trans_error( 'Invalid request.' );
    }
    if ( $model eq 'author' ) {
        return _upload_user( $app );
    }
    my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
    if ( $model eq 'asset' ) {
        my %params = ( rename => 1, format_LF => 0, singler => 1, no_asset => 1, );
        my $import_zip = upload( $app, $blog, 'zip', site_path( $blog ), \%params );
        return $app->error( $plugin->translate( 'Upload failed.' ) ) unless (-f $import_zip );
        #eval { require Archive::Zip };
        #if ( $@ ) {
        #    return $app->trans_error( 'Archive::Zip is required.' );
        #}
        require File::Basename;
        require MT::FileMgr;
        my $dir = File::Basename::dirname( $import_zip );
        $dir =~ s{(?!\A)/+\z}{};
        my $archive = Archive::Zip->new();
        unless ( $archive->read( $import_zip ) == AZ_OK ) {
            die 'Read error( Archive::Zip ).';
        }
        my @members = $archive->members();
        my $fmgr = MT::FileMgr->new( 'Local' );
        for my $member ( @members ) {
            my $out = $member->fileName;
            $out =~ s!^(?:/|\\)+!!;
            my $original = $out;
            my $basename = file_label( File::Basename::basename( $out ) );
            next if ( $basename =~ /^\./ );
            $out = File::Spec->catfile ( $dir, $out );
            # if ( $fmgr->exists( $out ) ) {
                # $out = uniq_filename( $out );
            # }
            $archive->extractMemberWithoutPaths( $member->fileName, $out );
            next unless -f $out;
            if (! allow_upload( $out ) ) {
                unlink $out;
                next;
            }
            my %params = ( file => $out,
                           author => $user,
                           label => $basename, );
            my $item = save_asset( $app, $blog, \%params, 1 ) or die;
            $do = 1;
        }
        $fmgr->delete( $import_zip );
    }
    my $category_sep = $app->config( 'ImportExportCategorySeparator' ) || '_';
    my $category_key = $app->config( 'ImportExportCategoryKey' ) || 'label';
    my $category_delim = $app->config( 'ImportExportCategoryDelim' ) || ',';
    my $snippet_sep = $app->config( 'ImportExportSnippetSeparator' ) || ':';
    my $snippet_delim = $app->config( 'ImportExportSnippetDelimiter' ) || ';';
    $category_sep = quotemeta( $category_sep );
    $category_delim = quotemeta( $category_delim );
    $snippet_sep = quotemeta( $snippet_sep );
    $snippet_delim = quotemeta( $snippet_delim );
    my $category_class = 'category';
    if ( $model eq 'page' ) {
        $category_class = 'folder';
    }
    my $object_ds;
    if ( ( $model eq 'entry' ) || ( $model eq 'page' ) ) {
        $object_ds = 'entry';
    } elsif ( ( $model eq 'category' ) || ( $model eq 'folder' ) ) {
        $object_ds = 'category';
    } else {
        $object_ds = $model;
    }
    my $blog_id = $app->param( 'blog_id' );
    my $csv = csv_new() or return $app->trans_error( 'Neither Text::CSV_XS nor Text::CSV is available.' );
    my %params = ( rename => 1, format_LF => 1, singler => 1, no_asset => 1, );
    my $import_csv = upload( $app, $blog, $model, $tmp_dir, \%params );
    if ( $model eq 'asset' ) {
        if (! -f $import_csv ) {
            if ( $do ) {
                if ( MT->version_id =~ /^5\.0/ ) {
                    return $app->redirect( $app->uri( mode => 'list_' . $model,
                                                      args => { blog_id => $blog_id, saved => 1 } ) );
                } else {
                    return $app->redirect( $app->uri( mode => 'list',
                                                      args => { _type => $model, blog_id => $blog_id, saved => 1 } ) );
                }
            }
        }
    }
    return $app->error( $plugin->translate( 'Upload failed.' ) ) unless ( -f $import_csv );
    my $i = 0;
    open my $fh, '<', $import_csv;
    my @column_names;
    while ( my $columns = $csv->getline( $fh ) ) {
        if (! $i ) {
            for my $cell ( @$columns ) {
                push ( @column_names, $cell );
            }
        } else {
            my $object;
            my @categories;
            my @assets;
            my $category_parent;
            my $category_label;
            my $file_path;
            my $j = 0;
            my $obj_blog_id = undef;
            for my $cell ( @$columns ) {
                my $cname = $column_names[ $j ];
                if ( $cname eq 'blog_id' ) {
                    $obj_blog_id = $cell;
                } elsif ( $cname eq 'parent' ) {
                    if ( $object_ds eq 'category' ) {
                        $category_parent = 1;
                    }
                } elsif ( $cname eq 'label' ) {
                    if ( $object_ds eq 'category' ) {
                        $category_label = $cell;
                    }
                } elsif ( $cname eq 'file_path' ) {
                    if ( $model eq 'asset' ) {
                        $file_path = $cell;
                    }
                }
                $j++;
            }
            if ( $object_ds eq 'asset' ) {
                $obj_blog_id = undef;
            }
            my $cat_blog_id = $obj_blog_id || $blog_id;
            my $k = 0;
            if ( ( $object_ds eq 'category' ) && (! $category_parent ) ) {
                $object = __get_the_category( $cat_blog_id, $model, $category_label, $category_key, $category_sep )
            } elsif ( $object_ds eq 'asset' ) {
                $object = $app->model( $model )->get_by_key( { blog_id => $blog_id,
                                                               class => '*',
                                                               file_path => $file_path } );
            } else {
                $object = $app->model( $model )->new;
            }
            $object->blog_id( $obj_blog_id );
#            my %meta;
            for my $cell ( @$columns ) {
                my $guess_encoding = MT::I18N::guess_encoding( $cell );
                unless ( $guess_encoding =~ /^utf-?8$/i ) {
                    $cell = utf8_on( MT::I18N::encode_text( $cell, 'cp932', 'utf8' ) );
                }
                my $cname = $column_names[ $k ];
                $cname = trim( $cname );
                if ( $object->has_column( $cname ) ) {
                    if ( $column_names[ $k ] =~ /_on$/ ) {
                        if ( $cell ) {
                            $cell =~ s/^\t//;
                        }
                    }
                    if ( $object_ds eq 'asset' && $cname eq 'parent' && ! $cell ) {
                        $cell = undef; # without this, 'asset_parent = 0' by DBPatch, template tag does not work.
                    }
                    if ( $cname =~ /^field\.(.*$)/ ) {
                        # Set CustomField Asset
                        my $field_basename = $1;
                        my $field_blog_id = $object->blog_id;
                        my $field_type;
                        $field_type = $r->cache( 'field_type:' . $field_blog_id . ':' . $field_basename );
                        if (! $field_type ) {
                            my $field = MT->model( 'field' )->load( { blog_id => [ 0, $field_blog_id ],
                                                                      basename => $field_basename },
                                                                    { limit => 1 } );
                            if ( $field ) {
                                $field_type = $field->type;
                                $r->cache( 'field_type:' . $field_blog_id . ':' . $field_basename, $field_type );
                            }
                        }
                        if ( $field_type ) {
                            if ( ( $field_type eq 'file' ) || ( $field_type eq 'image' ) ||
                                 ( $field_type eq 'video' ) || ( $field_type eq 'audio' ) ) {
                                if ( $cell && $cell =~ /^%[ar]/ ) {
                                    my $asset = MT::Asset->load( { blog_id => $field_blog_id,
                                                                   file_path => $cell,
                                                                   class => '*', } );
                                    unless ( $asset ) {
                                        my $file = $cell;
                                        my $site_path = site_path( $blog );
                                        $file =~ tr{/}{\\} if is_windows();
                                        $file =~ s/%r/$site_path/;
                                        if ( -f $file && allow_upload( $file ) ) {
                                            unless ( $object->id ) {
                                                $object->save or die $object->errstr;
                                            }
                                            my %param = (
                                                'file' => $file,
                                                'object' => $object,
                                            );
                                            $asset = save_asset( $app, $blog, \%param, 1 );
                                        }
                                    }
                                    if ( $asset ) {
                                        push ( @assets, $asset );
                                        my $asst_id = $asset->id;
                                        my $url = $asset->url;
                                        my $label = MT->translate( 'View image' );
                                        if ( $field_type ne 'image' ) {
#                                            $label = MT->translate( 'View' );
                                            $label = $asset->file_name;
                                        }
                                        $cell = qq{<form mt:asset-id="$asst_id" class="mt-enclosure mt-enclosure-$field_type" style="display: inline;"><a href="$url">$label</a></form>};
                                    }
                                }
                            }
                        }
                        if ( $field_type ne 'snippet' ) {
                            $object->$cname( $cell ) if $cname;
                        } else {
                            if ( $cell ) {
                                my $data;
                                my @values = split( /$snippet_delim/, $cell );
                                for my $val ( @values ) {
                                    my @key_val = split( /$snippet_sep/, $val );
                                    $data->{ $key_val[0] } = $key_val[1];
                                }
#                               require MT::Serialize;
#                               my $ser = MT::Serialize->serialize( \$data );
#                                $object->$cname( $ser ) if $cname;
                                $object->$cname( $data );
                            }
                        }
                    } else {
                        $object->$cname( $cell ) if $cname;
                    }
                } elsif ( $cname eq 'tags' ) {
                    if ( $app->model( $model )->isa( 'MT::Taggable' ) ) {
                        my @tags = split( /,/, $cell );
                        $object->set_tags( @tags );
                    }
                } elsif ( $cname eq 'category' ) {
                    my @cats = split( /$category_delim/, $cell );
                    for my $label( @cats ) {
                        my $category = __get_the_category( $cat_blog_id, $category_class, $label, $category_key, $category_sep );
                        push( @categories, $category );
                    }
                } elsif ( $cname eq 'asset' ) {
                    if ( $cell && $cell =~ /^%[ar]/ ) {
                        my $asset = MT::Asset->load( { blog_id => $object->blog_id,
                                                       file_path => $cell,
                                                       class => '*', } );
                        unless ( $asset ) {
                            my $file = $cell;
                            my $site_path = site_path( $blog );
                            $file =~ tr{/}{\\} if is_windows();
                            $file =~ s/%r/$site_path/;
                            if ( -f $file && allow_upload( $file ) ) {
                                unless ( $object->id ) {
                                    $object->save or die $object->errstr;
                                }
                                my %param = (
                                    'file' => $file,
                                    'object' => $object,
                                );
                                $asset = save_asset( $app, $blog, \%param, 1 );
                            }
                        }
                        if ( $asset ) {
                            push ( @assets, $asset );
                        }
                    }
                }
                $k++;
            }
            if (! defined( $obj_blog_id ) ) {
                $object->blog_id( $blog_id );
            }
            if ( (! $user->is_superuser ) && ( $blog_id ) ) {
                if ( $object->blog_id != $blog_id ) {
                    return $app->trans_error( 'Permission denied.' );
                }
            }
            $object->save or die $object->errstr;
            $do = 1;
            if ( @categories ) {
                $object = __set_the_category( $object, \@categories );
            }
            if ( @assets ) {
                if ( ( $object_ds eq 'entry' ) || ( $object_ds eq 'category' ) ) {
                    for my $asset( @assets ) {
                        my $object_asset = MT::ObjectAsset->get_by_key( { blog_id => $object->blog_id,
                                                                          asset_id => $asset->id,
                                                                          object_ds => $object_ds,
                                                                          object_id => $object->id } );
                        $object_asset->save or die $object_asset->errstr;
                    }
                }
            }
            if ( $object_ds eq 'entry' ) {
                $object = __set_entry_default( $app, $object );
            }
            MT->run_callbacks( 'MT::App::CMS::import_object.' . $model, $app, $object, \@column_names, $columns );
        }
        $i++;
    }
    unlink $import_csv;
    if ( $do ) {
        return $app->redirect( $app->uri( mode => 'list',
                                          args => { _type => $model, blog_id => $blog_id, saved => 1 } ) );
    }
    $app->add_return_arg( saved => 1 );
    $app->call_return;
}

sub _export_object {
    my $app = shift;
    my $blog = $app->blog;
    my $model = $app->param( '_type' );
    if (! $blog ) {
        if ( $model eq 'asset' ) {
            return $app->trans_error( 'Invalid request.' );
        }
        require MT::Blog;
        $blog = MT::Blog->load( { class => [ 'blog', 'website' ] }, { limit => 1 } );
    } else {
        if ( $model eq 'author' ) {
            return $app->trans_error( 'Invalid request.' );
        }
    }
    my @models = ( 'author', 'entry', 'page', 'category', 'folder', 'asset', 'field' );
    if (! grep( /^$model$/, @models ) ) {
        return $app->trans_error( 'Invalid request.' );
    }
    if ( $model eq 'author' ) {
        return _download_user( $app );
    }
    my $user = $app->user;
    my $admin = $user->is_superuser;
    my $blog_id = $app->param( 'blog_id' );
    my $csv = csv_new() or return $app->trans_error( 'Neither Text::CSV_XS nor Text::CSV is available.' );
    my $terms;
    $terms = { blog_id => $blog_id } if $blog_id;
    if ( $model eq 'asset' ) {
        if ( $app->param( 'asset_zip' ) ) {
            return _download_assets( $app );
        }
        $terms->{ class } = '*';
    }
    my $iter = $app->model( $model )->load_iter( $terms );
    $app->{ no_print_body } = 1;
    my $ts = current_ts();
    $app->set_header( 'Content-Disposition' => "attachment; filename=csv_$ts.csv" );
    $app->send_http_header( 'text/csv' );
    my $publishcharset = uc($app->config( 'PublishCharset' ) || '');
    my $column_names = $app->model( $model )->column_names;
    my @header = ();
    push( @header, 'id' );
    my $object_ds;
    for my $column ( @$column_names ) {
        push( @header, $column ) if ( $column ne 'id' );
    }
    my @snippets;
    if ( $app->model( $model )->has_meta ) {
        require CustomFields::Field;
        my @fields = CustomFields::Field->load( { blog_id => [ $blog_id, 0 ], obj_type => $model } );
        for my $field ( @fields ) {
            push( @$column_names, 'field.' . $field->basename );
            if ( $field->type eq 'snippet' ) {
                push( @snippets, 'field.' . $field->basename );
            }
            push( @header, 'field.' . $field->basename );
        }
    }
    if ( $app->model( $model )->isa( 'MT::Taggable' ) ) {
        push( @$column_names, 'tags' );
        push( @header, 'tags' );
    }
    if ( ( $model eq 'entry' ) || ( $model eq 'page' ) ) {
        push( @$column_names, 'category' );
        push( @header, 'category' );
        $object_ds = 'entry';
    } elsif ( ( $model eq 'category' ) || ( $model eq 'folder' ) ) {
        $object_ds = 'category';
    } else {
        $object_ds = $model;
    }
    my $category_sep   = $app->config( 'ImportExportCategorySeparator' ) || '_';
    my $category_key   = $app->config( 'ImportExportCategoryKey' )       || 'label';
    my $category_delim = $app->config( 'ImportExportCategoryDelim' )     || ',';
    my $snippet_sep    = $app->config( 'ImportExportSnippetSeparator' )  || ':';
    my $snippet_delim  = $app->config( 'ImportExportSnippetDelimiter' )  || ';';
    unshift( @$column_names, 'id' );
    if ( $csv->combine( @header ) ) {
        my $string = $csv->string;
        if ( $publishcharset ne 'shift_jis' ) {
            $string = utf8_off( $string );
            $string = MT::I18N::encode_text( $string, 'utf8', 'cp932' );
        }
        $app->print( $string, "\n" );
    }
    while ( my $object = $iter->() ) {
        my @fields = ();
        push( @fields, $object->id );
        for my $column ( @$column_names ) {
            if ( $object->has_column( $column ) ) {
                my $value = $object->$column;
                if (! grep( /^$column$/, @snippets ) ) {
                    if ( $column =~ /_on$/ ) {
                        if ( $value ) {
                            $value = "\t$value";
                        }
                    }
                    if ( $model eq 'asset' ) {
                        if ( ( $column eq 'file_path' ) || ( $column eq 'url' ) ) {
                            $value = path2relative( $value, $blog );
                        }
                        if ( $column eq 'parent' && ! $value ) {
                            $value = undef;
                        }
                    }
                    push( @fields, $value ) if ( $column ne 'id' );
                } else {
                    if (! ref $value ) {
                       require MT::Serialize;
                       $value = MT::Serialize->unserialize( $value );
                    }
                    my $params = ( ref $value ) eq 'REF' ? $$value : $value;
                    my @snippet;
                    for my $key( keys %$params ) {
                        my $val = $params->{ $key };
                        my $data = $key . $snippet_sep . $val;
                        push ( @snippet, $data );
                    }
                    push( @fields, join( $snippet_delim, @snippet ) );
                }
            } elsif ( $column eq 'tags' ) {
                my @tags = $object->get_tags;
                my $tag = join( ',', @tags );
                push( @fields, $tag );
            } elsif ( $column eq 'category' ) {
                if ( $object_ds eq 'entry' ) {
                    my @cats;
                    my $primary_category = $object->category;
                    push ( @cats, $primary_category ) if $primary_category;
                    my $categories = $object->categories;
                    for my $cat ( @$categories ) {
                        if ( $cat->id != $primary_category->id ) {
                            push ( @cats, $cat );
                        }
                    }
                    my @cat_strs;
                    for my $category ( @cats ) {
                        my $cat_str = __make_cat_path( $category, $category_key, $category_sep );
                        push( @cat_strs, $cat_str );
                    }
                    push( @fields, join( $category_delim, @cat_strs ) );
                }
            }
        }
        MT->run_callbacks( 'MT::App::CMS::export_object.' . $model, $app, $object, \@header, \@fields );
        if ( $csv->combine( @fields ) ) {
            my $string = $csv->string;
            if ( $publishcharset ne 'shift_jis' ) {
                $string = utf8_off( $string );
                $string = MT::I18N::encode_text( $string, 'utf8', 'cp932' );
            }
            $app->print( $string, "\n" );
        } else {
            my $err = $csv->error_input;
            $app->print( "combine() failed on argument: ", $err, "\n" );
        }
    }
}

sub _cb_ts_list_author {
    my ( $cb, $app, $tmpl ) = @_;
    my $insert = _tmpl();
    if ( MT->version_number >= 5 ) {
        $insert = '<ul>' . $insert . '</li></ul>';
        $$tmpl =~ s/(<div\sclass="listing-filter">)/$insert$1/sg;
    } else {
        $$tmpl =~ s{(<ul\sclass="action-link-list">.*?</li>).*?(</ul>)}{$1$insert$2}sg;
    }
}

sub _download_user {
    my $app = shift;
    my $plugin = MT->component( 'UploadUser' );
    my $user = $app->user;
    my $admin = $user->is_superuser
        or return $app->trans_error( 'Permission denied.' );
    require MT::Author;
    my $iter = MT::Author->load_iter( undef );
    my $csv = csv_new() or return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    $app->{ no_print_body } = 1;
    my $ts = current_ts();
    $app->set_header( 'Content-Disposition' => "attachment; filename=csv_$ts.csv" );
    if ( $app->is_secure ) {
        $app->set_header( 'Pragma' => '' );
    }
    $app->send_http_header( 'text/csv' );
    my $publishcharset = uc($app->config( 'PublishCharset' ) || '');
    require MT::Role;
    require MT::Association;
    my $column_names = MT->model( 'author' )->column_names;
    my @header = ();
    require CustomFields::Field;
    my @fields = CustomFields::Field->load( { obj_type => 'author' } );
    for my $field ( @fields ) {
        push ( @$column_names, 'field.' . $field->basename );
    }
    for my $column ( @$column_names ) {
        if ( ( $column ne 'entry_prefs' ) && ( $column ne 'id' ) ) {
            push ( @header, $column );
        }
    }
    if ( $csv->combine( @header ) ) {
        my $string = $csv->string;
        if ( $publishcharset ne 'shift_jis' ) {
            $string = utf8_off( $string );
            $string = MT::I18N::encode_text( $string, 'utf8', 'cp932' );
        }
        $app->print( $string, "\n" );
    }
    while ( my $author = $iter->() ) {
        my @fields = ();
        for my $column ( @$column_names ) {
            if ( ( $column ne 'password' ) && ( $column ne 'entry_prefs' )
                    && ( $column ne 'id' ) ) {
                my $value = $author->$column;
                if ( ( $column =~ /_on$/ ) && ( $value =~ /^[0-9]{14}$/ ) ) {
                    $value = "\t$value";
                }
                push ( @fields, $value );
            } else {
                if ( $column eq 'password' ) {
                    push ( @fields, '' );
                }
            }
        }
        my @assoc = MT::Association->load( { author_id => $author->id, type => 1 } );
        for my $association ( @assoc ) {
            my $role = MT::Role->load( $association->role_id );
            if ( $role ) {
                my $str = $association->blog_id . '_' . $role->name;
                push ( @fields, $str );
            }
        }
        if ( $csv->combine( @fields ) ) {
            my $string = $csv->string;
            if ( $publishcharset ne 'shift_jis' ) {
                $string = utf8_off( $string );
                $string = MT::I18N::encode_text( $string, 'utf8', 'cp932' );
            }
            $app->print( $string, "\n" );
        } else {
            my $err = $csv->error_input;
            $app->print( "combine() failed on argument: ", $err, "\n" );
        }
    }
}

sub _upload_user {
    my $app = shift;
    my $plugin = MT->component( 'UploadUser' );
    require MT::Author;
    require MT::Role;
    require MT::Permission;
    my $user  = $app->user;
    my $admin = $user->is_superuser
        or return $app->trans_error( 'Permission denied.' );
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
    my %params = ( rename => 1, format_LF => 1, singler => 1, no_asset => 1, );
    my $default = $app->config( 'UploadableMode' );
    $app->config( 'UploadableMode', ( $default ? $default . ',' . $app->mode : $app->mode ) );
    my $tmp_filename = upload( $app, undef, 'author', $tmp_dir, \%params );

    require ImportExportObject::Util;
    ImportExportObject::Util::import_author_from_csv( $tmp_filename );

    unlink $tmp_filename;
    $app->add_return_arg( saved => 1 );
    $app->call_return;
}

sub _download_assets {
    my $app = shift;
    my $blog = $app->blog;
    require MT::Asset;
    require File::Basename;
    require File::Spec;
    #eval { require Archive::Zip };
    #if ( $@ ) {
    #    return $app->trans_error( 'Archive::Zip is required.' );
    #}
    my @dirs;
    my $archiver = Archive::Zip->new();
    my @assets = MT::Asset->load( { blog_id => $blog->id, class => '*' } );
    my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
    for my $asset ( @assets ) {
        my $new = path2relative( $asset->file_path, $blog );
        $new =~ s!^.*?/!/!;
        $new = MT::I18N::utf8_off( $new );
        $archiver->addFile( $asset->file_path, $new );
    }
    my ( $hndl, $tmp_file ) = tempfile( File::Spec->catfile( $tmp_dir, 'XXXXXXXXXXX' ), SUFFIX => '.zip' );
    $archiver->writeToFileNamed( $tmp_file );
    if ( -f $tmp_file ) {
        $app->{ no_print_body } = 1;
        my $basename = File::Basename::basename( $tmp_file );
        $app->set_header( 'Content-Disposition' => "attachment; filename=$basename" );
        $app->set_header( 'Pragma' => '' );
        $app->send_http_header( 'application/zip' );
        if ( open( my $fh, '<', $tmp_file ) ) {
            binmode $fh;
            my $data;
            while ( read $fh, my ( $chunk ), 8192 ) {
                $data .= $chunk;
                $app->print( $chunk );
            }
            close $fh;
        }
        unlink $tmp_file;
    }
}

sub __set_the_category {
    my ( $entry, $categories ) = @_;
    my $is_new = $entry->category ? 0 : 1;
    my @saved_cats;
    my $i = 1;
    my $blog = $entry->blog;
    require MT::Placement;
    for my $category ( @$categories ) {
        my $is_primary = 0;
        if ( $i == 1 ) {
            $is_primary = 1;
        }
        my $place = MT::Placement->get_by_key( { blog_id => $blog->id,
                                                 category_id => $category->id,
                                                 entry_id => $entry->id,
                                                 is_primary => $is_primary,
                                             } );
        $place->save or die $place->errstr;
        push ( @saved_cats, $category->id );
        $i++;
    }
    if (! $is_new ) {
        my @placement = MT::Placement->load( blog_id => $blog->id,
                                             entry_id => $entry->id, );
        for my $place ( @placement ) {
            my $place_id = $place->id;
            if ( (! scalar @saved_cats ) || (! grep( /^$place_id$/, @saved_cats ) ) ) {
                $place->remove or die $place->errstr;
            }
        }
    }
    $entry->clear_cache();
    return $entry;
}

sub __set_entry_default {
    my ( $app, $entry ) = @_;
    my $blog = $entry->blog || $app->blog;
    my $user = $app->user;
    if (! $entry->author_id ) {
        unless ( defined $user ) {
            return undef;
        }
        $entry->author_id( $user->id );
    } else {
        if (! $user ) {
            require MT::Author;
            $user = MT::Author->load( $entry->author_id );
            if (! defined $user ) {
                return undef;
            }
        }
    }
    if (! $entry->created_by ) {
        $entry->created_by( $entry->author_id );
    }
    if (! $entry->modified_by ) {
        $entry->modified_by( $entry->author_id );
    }
    if (! $entry->status ) {
        $entry->status( $blog->status_default );
    }
    if (! $entry->allow_comments ) {
        $entry->allow_comments( $blog->allow_comments_default );
    }
    if (! $entry->allow_pings ) {
        $entry->allow_pings( $blog->allow_pings_default );
    }
    if (! $entry->class ) {
        $entry->class( 'entry' );
    }
    if (! $entry->authored_on ) {
        $entry->authored_on( current_ts( $blog ) );
    }
    if (! $entry->allow_pings ) {
        if (! $entry->atom_id ) {
            $entry->atom_id( $entry->make_atom_id() );
        }
    }
    $entry->clear_cache();
    return $entry;
}

sub __get_the_category {
    my ( $blog_id, $model, $str, $col, $category_sep ) = @_;
    my @split = split( /$category_sep/, $str );
    my $parent_id = 0;
    my $category;
    for my $name ( @split ) {
        $category = MT->model( $model )->get_by_key( { blog_id => $blog_id,
                                                       $col => $name,
                                                       parent => $parent_id,
                                                     }
                                                   );
        if (! $category->id ) {
            if (! $category->label ) {
                $category->label( $name );
            }
            $category->save or die $category->errstr;
        }
        $parent_id = $category->id;
    }
    return $category;
}

sub __make_cat_path {
    my ( $cat, $col, $category_sep ) = @_;
    my @parent_categories = $cat->parent_categories;
    my @cat_strs;
    if ( @parent_categories ) {
        my @parent_categories = reverse( @parent_categories );
        for my $category ( @parent_categories ) {
            push( @cat_strs, $category->$col );
        }
    }
    push( @cat_strs, $cat->$col );
    return join( $category_sep, @cat_strs );
}

1;
