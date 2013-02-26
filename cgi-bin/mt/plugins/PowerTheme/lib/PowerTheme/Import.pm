package PowerTheme::Import;
use strict;

use strict;
use lib qw( addons/Commercial.pack/lib );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( utf8_off current_ts upload utf8_on file_label save_asset 
                       csv_new plugin_template_path site_path uniq_filename path2relative
                       allow_upload is_windows
                     );

my $plugin = MT->component( 'PowerTheme' );

sub _import_object {
    my $app = shift;

    my $blog = shift;
    my $theme_id = shift;
    return unless $theme_id;
    my $theme = MT->component( $theme_id );
    my $model = shift;
    
    require MT::Request;
    require MT::Asset;
    require MT::ObjectAsset;
    my $r = MT::Request->instance;
    my $plugin = MT->component( 'ImportExportObject' );
#    my $blog = $app->blog;
    my $user = $app->user;
    my $do;
#     my $model = $app->param( '_type' );
    my @models = ( 'entry', 'page', 'category', 'folder', 'asset', 'field' );
    if (! grep( /^$model$/, @models ) ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $tmp_dir = $app->config( 'TempDir' );
    $tmp_dir = $app->config( 'TmpDir' ) unless $tmp_dir;
    my $category_sep = $app->config( 'ImportExportCategorySeparator' ) || '_';
    my $category_key = $app->config( 'ImportExportCategoryKey' ) || 'label';
    my $category_delim = $app->config( 'ImportExportCategoryDelim' ) || ',';
    $category_sep = quotemeta( $category_sep );
    $category_delim = quotemeta( $category_delim );
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
#    my $blog_id = $app->param( 'blog_id' );
    my $blog_id = $blog->id;
    my $csv = csv_new() || return $app->trans_error( 'Neither Text::CSV_XS nor Text::CSV is available.' );
    my %params = ( rename => 1, format_LF => 1, singler => 1, no_asset => 1, );
    my $import_csv = File::Spec->catfile( $theme->path, 'import', $model . '.csv' );
    unless ( -f $import_csv ) {
        return;
    }
    my $i = 0;
    open my $fh, "<", $import_csv;
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
            my $cat_blog_id = $obj_blog_id;
            if (! $cat_blog_id ) {
                $cat_blog_id = $blog_id;
            }
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
            for my $cell ( @$columns ) {
                $cell = utf8_on( MT::I18N::encode_text( $cell, 'cp932', 'utf8' ) );
                my $cname = $column_names[ $k ];
                if ( $object->has_column( $cname ) ) {
                    if ( $column_names[ $k ] =~ /_on$/ ) {
                        if ( $cell ) {
                            $cell =~ s/^\t//;
                        }
                    }
                    if ( $cname =~ /^field\.(.*$)/ ) {
                        # Set CustomField Asset
                        my $field_basename = $1;
if ( $field_basename eq 'contactformselector' ) {
    my $contactformgroup = MT->model( 'contactformgroup' )->load( { name => $cell,
                                                                    blog_id => $blog_id,
                                                                  }
                                                                );
    if ( $contactformgroup ) {
        $cell = $contactformgroup->id;
    }
} elsif ( $field_basename eq 'entrysimilargroup' ) {
    my $entrygroup = MT->model( 'entrygroup' )->load( { name => $cell,
                                                        blog_id => $blog_id,
                                                      }
                                                    );
    if ( $entrygroup ) {
        $cell = $entrygroup->id;
    }
} 
# elsif ( $field_basename eq 'entrysitecaptcha' ) {
#     my $asset = MT->model( 'asset' )->load( { file_path => $cell,
#                                               blog_id => $object->blog_id,
#                                             }
#                                           );
#     if ( $asset ) {
#         my $asset_id = $asset->id;
#         my $asset_url = $asset->url;
#         $cell = <<CELL;
# <form mt:asset-id="$asset_id" class="mt-enclosure mt-enclosure-image" style="display: inline;"><a href="$asset_url">表示</a></form>
# CELL
#     }
# }


                        my $field_blog_id = $object->blog_id;
                        $field_blog_id = $blog_id; # FIXED
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
                                if ( $cell && ( ( $cell =~ /^\%r/ ) || ( $cell =~ /^\%a/ ) ) ) {
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
                                                unless ( $object->blog_id ) {
                                                    $object->blog_id( $field_blog_id );
                                                }
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
                    }
                    $object->$cname( $cell ) if $cname;
                } elsif ( $cname eq 'tags' ) { # FIX
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
            MT->run_callbacks( ref $app . '::import_object.' . $model, $app, $object, \@column_names, $columns );
        }
        $i++;
    }
#     unlink $import_csv;
#     if ( $do ) {
#         return $app->redirect( $app->uri( mode => 'list_' . $model ,
#                                           args => { blog_id => $blog_id, saved => 1 } ) );
#     }
#     $app->add_return_arg( saved => 1 );
#     $app->call_return;
}

sub __set_the_category {
    my ( $entry, $categories ) = @_;
    my $is_new = 0;
    if (! $entry->category ) {
        $is_new = 1;
    }
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
    my $blog = $entry->blog;
    if (! $blog ) {
        $blog = $app->blog;
    }
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
#                                                       parent_id => $parent_id, # FIX
                                                       } );
        if (! $category->id ) {
            if (! $category->label ) {
                $category->label( $name );
            }
            $category->save or die $category->errstr;
        }
    }
    return $category;
}

1;