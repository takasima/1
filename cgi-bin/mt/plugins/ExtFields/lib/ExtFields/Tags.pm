package ExtFields::Tags;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( site_path site_url save_asset utf8_off is_windows );
use MT::Util qw( encode_html offset_time_list format_ts );
use ExtFields::Util;

sub _ext_fields_loop {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $entry   = $ctx->stash( 'entry' );
    my @excludes = $args->{ exclude_label } ? split( /,/, $args->{ exclude_label } ): ();
    my $sort_order = $args->{ sort_order };
    unless ( $sort_order ) {
        $sort_order = 'ascend';
    }
    my $entry_id = $entry->id;
    my @items = MT->model( 'extfields' )->load( { entry_id => $entry->id,
                                                  status   => 1,
                                                  ( @excludes ? ( label => { 'not' => \@excludes } ) : () ),
                                                }, {
                                                  'sort' => 'sort_num',
                                                  direction => $sort_order,
                                                },
                                              );
    my $res = '';
    my $i   = 1;
    require Digest::MD5;
    require MT::Request;
    my $r = MT::Request->instance;
    for my $extfields ( @items ) {
        my $exflag = 1;
        my $label = $extfields->label;
        my $hash = Digest::MD5::md5_hex( utf8_off( $label ) );
        my $stash_key = 'extfield-' . $entry_id . '-' . $hash;
        $r->cache( $stash_key, $extfields );
        if ( $exflag ) {
            my ( $asset, $asset_thumb );
            if ( $extfields->type eq 'file' || $extfields->type eq 'file_compact' ) {
                if ( $asset = $extfields->asset ) {
                    my $asset_id = $asset->id;
                    $asset_thumb = MT->model( 'asset' )->load( { class => "*",
                                                                 parent => $asset_id,
                                                               }
                                                             );
                }
            }
            local $ctx->{ __stash }{ 'entry' }          = $entry;
            local $ctx->{ __stash }{ 'asset' }          = $asset;
            local $ctx->{ __stash }{ 'asset_thumb' }    = $asset_thumb;
            local $ctx->{ __stash }{ 'field' }          = $extfields;
            local $ctx->{ __stash }{ 'label' }          = $label;
            local $ctx->{ __stash }{ 'counter' }        = $i;
            local $ctx->{ __stash }{ 'field_id' }       = $extfields->id;
            local $ctx->{ __stash }{ 'text' }           = $extfields->text;
            local $ctx->{ __stash }{ 'num' }            = $extfields->sort_num;
            local $ctx->{ __stash }{ 'type' }           = $extfields->type;
            local $ctx->{ __stash }{ 'name' }           = $extfields->name;
            local $ctx->{ __stash }{ 'multiple' }       = $extfields->multiple;
            local $ctx->{ __stash }{ 'cblabel' }        = $extfields->select_item;
            local $ctx->{ __stash }{ 'filetype' }       = $extfields->file_type;
            local $ctx->{ __stash }{ 'metadata' }       = $extfields->metadata;
            local $ctx->{ __stash }{ 'transform' }      = $extfields->transform;
            local $ctx->{ __stash }{ 'alt' }            = $extfields->alternative;
            local $ctx->{ __stash }{ 'desc' }           = $extfields->description;
            local $ctx->{ __stash }{ 'thumbnail' }      = $extfields->thumbnail;
            local $ctx->{ __stash }{ 'thumb_metadata'}  = $extfields->thumb_metadata;
            my $out = $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
            $res .= $out;
            $i++;
        }
    }
    $res;
}

# sub _ext_files {
#     my ( $ctx, $args, $cond ) = @_;
#     my $entry = $ctx->stash( 'entry' )
#                     or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
#     my $ext_files = $entry->ext_files;
#     return $ext_files || '';
# }

sub _ext_datas {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' )
                    or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $ext_datas = $entry->ext_datas;
    return $ext_datas || '';
}

sub _ext_field_export_data {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash( 'field' );
    my $select_item = '';
    my $alternative = '';
    my $metadata = '';
    my $file_type = '';
    my $multiple = '';
    my $file_path = '';
    my $thumbnail = '';
    my $type = $field->type;
    my $label = $field->label;
    $file_path = $field->file_path if $field->file_path;
    $multiple = $field->multiple if $field->multiple;
    $thumbnail = $field->thumbnail if $field->thumbnail;
    $metadata = $field->metadata if $field->metadata;
    $alternative = $field->alternative if $field->alternative;
    $select_item = $field->select_item if $field->select_item;
    $file_type = $field->file_type if $field->file_type;
    my $transform = $field->transform;
    my $compact = $field->compact;
    $transform = '1' unless $transform;
    my $url = '';
    my $text;
    if ( $type eq 'file' ) {
        $url = $field->text;
        $text = $field->description;
    } else {
        $text = $field->text;
    }
    return <<"FIELD";
-----
EXTFIELD:
TYPE:$type
LABEL:$label
URL:$url
ALTERNATIVE:$alternative
FILE_PATH:$file_path
FILE_TYPE:$file_type
METADATA:$metadata
MULTIPLE:$multiple
THUMBNAIL:$thumbnail
SELECT_ITEM:$select_item
TRANSFORM:$transform
COMPACT:$compact
$text
FIELD
}

sub _ext_field_multivals {
    my ( $ctx, $args, $cond ) = @_;
    my $multiple; my $text; my $type;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $multiple = $extfields->multiple;
            $text = $extfields->text;
            $type = $extfields->type;
        }
    } else {
        $multiple = $ctx->stash( 'multiple' );
        $text = $ctx->stash( 'text' );
        $type = $ctx->stash( 'type' );
    }
    my @multiples = split( /,/, $multiple);
    my @actives;
    if ( $text ) {
        @actives = split( /,/, $text);
    }
    my $res;
    for my $value ( @multiples ) {
        my $selected = 0;
        if ( $type eq 'cbgroup' ) {
            if ( $text ) {
                if ( grep( /^$value$/, @actives ) ) {
                    $selected = 1;
                }
            }
        } else {
            if ( $text ) {
                if ( $value eq $text ) {
                     $selected = 1;
                }
            }
        }
        local $ctx->{ __stash }{ 'value'} = $value;
        local $ctx->{ __stash }{ 'selected'} = $selected;
        my $out = $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
        $res .= $out;
    }
    $res;
}

sub _if_ext_field_selected {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'selected' ) || 0;
}

sub _ext_field_value {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'value' ) || '';
}

sub _ext_field_asset {
    my ( $ctx, $args, $cond ) = @_;
    my $asset;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( $extfields ) {
            $asset = $extfields->asset;
        }
    } else {
        $asset = $ctx->stash( 'asset' );
    }
    if ( defined $asset ) {
        local $ctx->{ __stash }{ asset } = $asset;
        my $out = $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
        return $out;
    }
}

sub _ext_field_multival {
    my ( $ctx, $args, $cond ) = @_;
    my $multiple; my $text; my $type;
    my $label = $args->{ label };
    my $glue = $args->{ glue } || '';
    my $active = $args->{ active };
    if ( $label ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $multiple = $extfields->multiple;
            $text = $extfields->text;
        }
    } else {
        $multiple = $ctx->stash( 'multiple' );
        $text = $ctx->stash( 'text' );
        $type = $ctx->stash( 'type' );
    }
    unless ( $glue ) {
        return $multiple;
    } else {
        my @multiples = split( /,/, $multiple );
        my @actives = split( /,/, $text );
        my @res;
        for my $item ( @multiples ) {
            if ( $active && $type eq 'cbgroup' ) {
                my $search = quotemeta( $item );
                if ( grep { $_ =~ /^$search$/ } @actives ) {
                    push( @res, $item );
                }
            } else {
                if ( $active && $type ne 'cbgroup' ) {
                    return $text;
                }
                push( @res, $item );
            }
        }
        return @res ? join( $glue, @res ) : '';
    }
    return '';
}

sub _ext_field_id {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            return $extfields->id || '';
        }
    } else {
        return defined $ctx->stash( 'field_id' ) ? $ctx->stash( 'field_id' ) : '';
    }
    return '';
}


sub _ext_field_name {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            return $extfields->name || '';
        }
    } else {
        return defined $ctx->stash( 'name' ) ? $ctx->stash( 'name' ) : '';
    }
    return '';
}

sub _ext_field_suffix {
    my ( $ctx, $args, $cond ) = @_;
    my $path;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $path = $extfields->text;
        }
    } else {
        $path = $ctx->stash( 'text' );
    }
    if ( $path ) {
        my @suffix = split( /\./, $path );
        if ( $path = pop( @suffix ) ) {
            return $path;
        }
    }
    return '';
}

sub _ext_field_alt {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            return $extfields->alternative;
        }
    } else {
        return defined $ctx->stash( 'alt' ) ? $ctx->stash( 'alt' ) : '';
    }
    return '';
}

sub _ext_field_desc {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $site_url = site_url( $blog );
    if ( is_windows() ) {
        $site_url =~ s/(.*)\\$/$1/;
    } else {
        $site_url =~ s/(.*)\/$/$1/;
    }
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            my $trans = $extfields->transform;
            my $text = $extfields->description;
            my $file_type = $extfields->file_type;
            my $url = $extfields->text;
            my $alt = $extfields->alternative;
            $alt = encode_html( $alt );
            my $metadata = $extfields->metadata;
            if ( $text =~ /(\[image:)(.*?)(\])/ ) {
                my $class = $2;
                my @metadatas = split( /,/, $metadata );
                my $search = quotemeta( $1 . $2 . $3 );
                if ( $file_type eq 'image' ) {
                    $url =~ s/%r/$site_url/;
                    my $tag = '<img src="' . $url . '" width="' . $metadatas[ 0 ] . '" height=' . $metadatas[ 1 ] . '" alt="' . $alt . '" class="' . $class . '" />';
                    $text =~ s/$search/$tag/;
                }
            }
            return ExtFields::Util::format_text( $trans, $text );
        }
    } else {
        my $trans = $ctx->stash( 'transform' );
        my $text = $ctx->stash( 'desc' );
        my $file_type = $ctx->stash( 'filetype' );
        my $url = $ctx->stash( 'text' );
        my $alt = $ctx->stash( 'alt' );
        $alt = encode_html( $alt );
        my $metadata = $ctx->stash( 'metadata' );
        if ( $text =~ /(\[image:)(.*?)(\])/ ) {
            my $class = $2;
            my @metadatas = split( /,/, $metadata );
            my $search = quotemeta( $1 . $2 . $3 );
            if ( $file_type eq 'image' ) {
                $url =~ s/%r/$site_url/;
                my $tag = '<img src="' . $url . '" width="' . $metadatas[ 0 ] . '" height=' . $metadatas[ 1 ] . '" alt="' . $alt . '" class="' . $class . '" />';
                $text =~ s/$search/$tag/;
            }
        }
        return defined $ctx->stash( 'desc' ) ? ExtFields::Util::format_text( $trans, $text ) : '';
    }
    return '';
}

sub _if_ext_field_non_empty {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            return $extfields->text ? 1 : 0;
        }
    } else {
        return $ctx->stash( 'text' ) ? 1 : 0;
    }
    return 0;
}

sub _if_entry_is_dynamic {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' ) 
        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    return $entry->is_dynamic ? 1 : 0;
}

sub _if_ext_field_compare {
    my ( $ctx, $args, $cond ) = @_;
    my $c_label = $args->{ label };
    my $c_text = $args->{ text };
    my $label = $ctx->stash( 'label' );
    my $text = $ctx->stash( 'text' );
    if ( $c_label && $c_text ) {
        if ( $c_label eq $label && $c_text eq $text ) {
            return 1;
        }
    } else {
        if ( $c_label ) {
            return ( $c_label eq $label );
        } elsif ( $c_text ) {
            return ( $c_text eq $text );
        }
    }
    return 0;
}

sub _ext_field_image_width {
    my ( $ctx, $args, $cond ) = @_;
    my $meta;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $meta = $extfields->metadata;
            unless ( $meta ) {
                if ( my $asset = $extfields->asset ) {
                    return $asset->image_width || '';
                }
            }
        }
    } else {
        $meta = $ctx->stash( 'metadata' );
    }
    if ( $meta ) {
        my @metas = split( /,/, $meta );
        if ( @metas ) {
            return $metas[ 0 ];
        }
    } else {
        if ( my $asset = $ctx->stash( 'asset' ) ) {
            return $asset->image_width || '';
        }
    }
    return '';
}

sub _ext_field_thumbnail_width {
    my ( $ctx, $args, $cond ) = @_;
    my $meta;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $meta = $extfields->thumb_metadata;
            unless ( $meta ) {
                if ( my $asset = $extfields->asset ) {
                    my $child_asset = MT->model( 'asset' )->load( { class => "*",
                                                                    parent => $asset->id,
                                                                  }
                                                                );
                    if ( $child_asset ) {
                        return $child_asset->image_width || '';
                    }
                }
            }
        }
    } else {
        $meta = $ctx->stash( 'thumb_metadata' );
    }
    if ( $meta && $meta != ',' ) {
        my @metas = split( /,/,$meta );
        if ( @metas ) {
            return $metas[ 0 ];
        }
    } else {
        if ( my $asset = $ctx->stash( 'asset_thumb' ) ) {
            return $asset->image_width || '';
        }
    }
    return '';
}

sub _ext_field_image_height {
    my ( $ctx, $args, $cond ) = @_;
    my $meta;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $meta = $extfields->metadata;
            unless ( $meta ) {
                if ( my $asset = $extfields->asset ) {
                    return $asset->image_height || '';
                }
            }
        }
    } else {
        $meta = $ctx->stash( 'metadata' );
    }
    if ( $meta ) {
        my @metas = split( /,/,$meta );
        if ( @metas ) {
            return $metas[ 1 ];
        }
    } else {
        if ( my $asset = $ctx->stash( 'asset' ) ) {
            return $asset->image_height || '';
        }
    }
    return '';
}

sub _ext_field_thumbnail_height {
    my ( $ctx, $args, $cond ) = @_;
    my $label = $args->{ label };
    my $meta;
    if ( $label ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $meta = $extfields->thumb_metadata;
            unless ( $meta ) {
                my $asset = $extfields->asset;
                my $child_asset = MT->model( 'asset' )->load( { class => "*",
                                                                parent => $asset->id,
                                                              }
                                                            );
                if ( $child_asset ) {
                    return $child_asset->image_height || '';
                }
            }
        }
    } else {
        $meta = $ctx->stash( 'thumb_metadata' );
    }
    if ( $meta && $meta != ',' ) {
        my @metas = split( /,/,$meta );
        if ( @metas ) {
            return $metas[ 1 ];
        }
    } else {
        if ( my $asset = $ctx->stash( 'asset_thumb' ) ) {
            return $asset->image_height || '';
        }
    }
    return '';
}

sub _ext_field_file_path {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $file_path;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->text;
        }
    } else {
        $file_path = $ctx->stash( 'text' );
    }
    if ( $file_path ) {
        my $site_url = site_url( $blog );
        $site_url = ExtFields::Util::remove_last_slash( $site_url );
        $file_path =~ s/%r/$site_url/;
        return $file_path;
    }
    return '';
}

sub _ext_field_file_date {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $file_path;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->text;
        }
    } else {
        $file_path = $ctx->stash( 'text' );
    }
    if ( $file_path ) {
        my $site_path = site_path( $blog );
        $file_path =~ s/%r/$site_path/;
        if ( is_windows() ) {
            $file_path =~ s/\//\\/g;
        }
        if ( -f $file_path ) {
            my @fdatas = stat( $file_path );
            my @tl = &offset_time_list( $fdatas[ 9 ], $blog );
            my $ts = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
            my $format = $args->{ 'format' };
            return format_ts( $format, $ts, $blog );
        }
    }
    return '';
}

sub _ext_field_file_size {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $unit = $args->{ unit };
    my $decimals = $args->{ decimals };
    my $file_path;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->text;
        }
    } else {
        $file_path = $ctx->stash( 'text' );
    }
    if ( $file_path ) {
        my $site_path = site_path( $blog );
        $file_path =~ s/%r/$site_path/;
        if ( is_windows() ) {
            $file_path =~ s/\//\\/g;
        }
        if ( -f $file_path ) {
            my @fdatas = stat( $file_path );
            my $size = $fdatas[ 7 ];
            if ( $unit eq 'kb' ) {
                $size = $size / 1024;
            }
            if ( $unit eq 'mb' ) {
                $size = $size / 1048576;
            }
            if ( $decimals =~ /[0-9]{1,}/ ) {
                if ( $decimals eq '0' ) {
                    $size = int( $size );
                } else {
                    $size =~ s/([0-9]*\.[0-9]{$decimals})[0-9]*/$1/;
                }
            }
            if ( ! $unit && ! $decimals ) {
                if ( $size > 1023 ) {
                    if ( $size > 1048575 ) {
                        $size = $size/1048576;
                        $size =~ s/([0-9]*\.[0-9])[0-9]*/$1/;
                        $size = $size . 'MB';
                    } else {
                        $size = $size/1024;
                        $size =~ s/([0-9]*\.[0-9])[0-9]*/$1/;
                        $size = $size . 'KB';
                    }
                } else {
                    $size =~ s/([0-9]*\.[0-9])[0-9]*/$1/;
                    $size = $size . 'Byte';
                }
            }
            return $size;
        }
    }
    return '0';
}

sub _ext_field_file_name {
    my ( $ctx, $args, $cond ) = @_;
    my $path;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $path = $extfields->text;
        }
    } else {
        $path =  $ctx->stash( 'text' );
    }
    if ( $path ) {
        my @pathes = split( /\//, $path );
        if ( $path = pop( @pathes ) ) {
            return $path;
        }
    }
    return '';
}

sub _ext_field_thumbnail {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $file_path;
    if ( my $label = $args->{ label } ) {
        require ExtFields::Extfields;
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->thumbnail;
        }
    } else {
        $file_path = $ctx->stash( 'thumbnail' );
    }
    if ( $file_path ) {
        my $site_url = site_url( $blog );
        $site_url = ExtFields::Util::remove_last_slash( $site_url );
        $file_path =~ s/%r/$site_url/;
        return $file_path;
    }
    return '';
}

sub _ext_field_cb_label {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            return $extfields->select_item;
        }
    } else {
        return defined $ctx->stash( 'cblabel' ) ? $ctx->stash( 'cblabel' ) : '';
    }
}

sub _ext_field_label {
    my ( $ctx, $args, $cond ) = @_;
    return defined $ctx->stash( 'label' ) ? $ctx->stash( 'label' ) : '';
}

sub _ext_field_text {
    my ( $ctx, $args, $cond ) = @_;
    my $format = $args->{ 'format' };
    my $blog = $ctx->stash( 'blog' );
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            my $text = $extfields->text;
            my $type = $extfields->type;
            if ( $type eq 'date' ) {
                return format_ts( $format, $text, $blog );
            } elsif ( $type eq 'textarea' ) {
                my $trans = $extfields->transform;
                return ExtFields::Util::format_text( $trans, $text );
            } else {
                return $text;
            }
        }
    } else {
        my $text = $ctx->stash( 'text' );
        my $type = $ctx->stash( 'type' );
        if ( $type eq 'date' ) {
            return format_ts( $format, $text, $blog );
        } elsif ( $type eq 'textarea' ) {
            my $trans = $ctx->stash( 'transform' );
            return ExtFields::Util::format_text( $trans, $text );
        } else {
            return $text;
        }
    }
    return '';
}

sub _ext_field_num {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'num' );
}

sub _if_ext_field_type {
    my ( $ctx, $args, $cond ) = @_;
    my $label = $args->{ label };
    my $type;
    if ( $label ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $type = $extfields->type;
        }
    } else {
        $type = $ctx->stash( 'type' );
    }
    if ( my $arg = $args->{ type } ) {
        return ( $arg eq $type );
    }
}

sub _if_ext_field_file_exists {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $file_path;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->text;
        }
    } else {
        $file_path = $ctx->stash( 'text' );
    }
    if ( $file_path ) {
        my $site_path = site_path( $blog );
        $file_path =~ s/%r/$site_path/;
        return -f $file_path ? 1 : 0;
    }
    return 0;
}

sub _if_ext_field_thumb_exists {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $label = $args->{ label };
    my $file_path;
    if ( $label ) {
        my $entry = $ctx->stash( 'entry' )
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->thumbnail;
        }
    } else {
        $file_path = $ctx->stash( 'thumbnail' );
    }
    if ( $file_path ) {
        my $site_path = site_path( $blog );
        $file_path =~ s/%r/$site_path/;
        return -f $file_path ? 1 : 0;
    }
    return 0;
}

sub _if_ext_field_type_image {
    my ( $ctx, $args, $cond ) = @_;
    my $type = '';
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $type = $extfields->file_type;
        }
    } else {
        $type = $ctx->stash( 'filetype' );
    }
    if ( $type ) {
        return $type eq 'image' ? 1 : 0;
    }
    return 0;
}

sub _if_ext_field {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' )
                    or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $label = $args->{ label };
    my $count;
    unless ( $label ) {
        $count = MT->model( 'extfields' )->count( { entry_id => $entry->id,
                                                    status => 1,
                                                  }
                                                );
    } else {
        $count = MT->model( 'extfields' )->count( { entry_id => $entry->id,
                                                    status => 1,
                                                    label => $label,
                                                  }
                                                );
    }
    return $count ? 1 : 0;
}

sub _ext_field_count {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' )
                    or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    return MT->model( 'extfields' )->count( { entry_id => $entry->id } );
}

sub _ext_field_counter {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'counter' ) || '';
}

sub _ext_field_file_thumbnail {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $width = $args->{ width };
    my $height = $args->{ height };
    return '' unless ( $width || $height );
    my $file_path; my $type; my $file_type;
    if ( my $label = $args->{ label } ) {
        my $entry = $ctx->stash( 'entry' ) 
                        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
        my $extfields = ExtFields::Util::get_field( $entry, $label );
        if ( defined $extfields ) {
            $file_path = $extfields->text;
            $type = $extfields->type;
            $file_type = $extfields->file_type;
        }
    } else {
        $file_path = $ctx->stash( 'text' );
        $type = $ctx->stash( 'type' );
        $file_type = $ctx->stash( 'filetype' );
    }
    return '' unless $file_path;
    return '' unless $type =~ /file/ && $file_type eq 'image';
    my $site_path = site_path( $blog );
    $file_path =~ s/%r/$site_path/;
    if ( is_windows() ) {
        $file_path =~ s/\//\\/g;
    }
    return '' unless -f $file_path;
    my @suffix = split( /\./, $file_path );
    my $ext = pop( @suffix );
    my $tumbfile = $file_path;
    my $filename_add;
    $filename_add .= '-thumb';
    $filename_add .= $width if $width;
    $filename_add .= 'x';
    $filename_add .= $height if $height;
    $filename_add .= '.';
    $filename_add .= $ext;
    $tumbfile =~ s/(^.*)\..*$/$1.$filename_add/e;
    unless ( -f $tumbfile ) {
        require MT::Image;
        my $img = MT::Image->new( Filename => $file_path );
        my( $blob, $w, $h );
        if ( $width && ! $height ) {
            ( $blob, $w, $h ) = $img->scale( Width => $width );
        }
        if ( $width && $height ) {
            ( $blob, $w, $h ) = $img->scale( Width => $width, Height => $height );
        }
        if (! $width && $height ) {
            ( $blob, $w, $h ) = $img->scale( Height => $height );
        }
        open FH, ">$tumbfile" || die "Can't create $tumbfile!";
        binmode FH;
        print FH $blob;
        close FH;
        my %asset_elements = (
            'parent' => $file_path,
            'file' => $tumbfile,
            'created_by' => '',
            'blog_id' => '',
            'label' => '',
            'description' => '',
            'author_id' => '',
        );
        save_asset( MT->app, $blog, \%asset_elements );
    }
    my $site_url = site_url( $blog );
    $site_path = quotemeta( $site_path );
    $tumbfile =~ s/$site_path/$site_url/;
    if ( is_windows() ) {
        $tumbfile =~ s/\\/\//g;
    }
    return $tumbfile;
}

1;