package ExtFields::Plugin;
use strict;
use lib qw( addons/PowerCMS.pack/lib plugins/SidebarAssets/lib );

use File::Basename;
use Image::Size;

use MT::Image;
use MT::Util qw( encode_html offset_time_list encode_url );

use SidebarAssets::Plugin;
use ExtFields::Util;
use PowerCMS::Util qw( site_path site_url is_image
                       set_upload_filename uniq_filename file_basename charset_is_utf8
                       is_power_edit is_windows current_user is_application move_file
                       copy_item
                     );

my $plugin = MT->component( 'ExtFields' );

sub _cb_tp_cfg_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $entry_fields = $tmpl->getElementById( 'entry_fields' ) ) {
        my $text =<<'MTML';
<__trans_section component="ExtFields">
    <li><input type="checkbox" name="entry_custom_prefs" id="entry-prefs-ext-field" value="ext-field" <mt:if name="entry_disp_prefs_show_ext-field"> checked="checked"</mt:if> class="cb" /> <label for="entry-prefs-ext-field"><__trans phrase="Extra Fields"></label></li>
</__trans_section>
MTML
        $entry_fields->innerHTML( $text );
    }
    if ( my $page_fields = $tmpl->getElementById( 'page_fields' ) ) {
        my $text =<<'MTML';
<__trans_section component="ExtFields">
    <li><input type="checkbox" name="page_custom_prefs" id="page-prefs-ext-field" value="ext-field" <mt:if name="page_disp_prefs_show_ext-field"> checked="checked"</mt:if> class="cb" /> <label for="page-prefs-ext-field"><__trans phrase="Extra Fields"></label></li>
</__trans_section>
MTML
        $page_fields->innerHTML( $text );
    }
}

sub _cb_post_clone {
    my ( $cb, %param ) = @_;
    my $app = MT->instance;
    return 1 if $app->param( 'clone_prefs_extfields' );
    my $state = $plugin->translate( 'Cloning extfield for blog...' );
    my $state_id = $plugin->translate( 'extfields' );
    my $callback = $param{ callback };
    $callback->( $state, $state_id );
    my $old_blog_id = $param{ old_blog_id };
    my $new_blog_id = $param{ new_blog_id };
    my $old_blog = MT->model( 'blog' )->load( { id => $old_blog_id } );
    my $old_site_path = site_path( $old_blog );
    my $q_old_site_path = quotemeta( $old_site_path );
    my $new_blog = MT->model( 'blog' )->load( { id => $new_blog_id } );
    my $new_site_path = File::Spec->catfile( $app->param( 'site_path_absolute' ), $app->param( 'site_path' ) );
    $new_site_path =~ s/\/$//;
    $new_site_path =~ s/\\$//;
    my $q_new_site_path = quotemeta( $new_site_path );
    my $entry_map = $param{ entry_map };
    my $terms = { blog_id => $old_blog_id };
    my $iter = MT->model( 'extfields' )->load_iter( $terms );
    my $counter = 0;
    while ( my $object = $iter->() ) {
        my $old_entry_id = $object->entry_id;
        if ( my $new_entry_id = $entry_map->{ $old_entry_id } ) {
            my $new_object = $object->clone_all();
            delete $new_object->{ column_values }->{ id };
            delete $new_object->{ changed_cols }->{ id };
            $new_object->blog_id( $new_blog_id );
            $new_object->entry_id( $new_entry_id );
            if ( my $old_asset_id = $object->asset_id ) {
                my $old_asset = MT->model( 'asset' )->load( { id => $old_asset_id } );
                if ( $old_asset ) {
                    my $old_file_path = $old_asset->file_path;
                    my $new_file_path = $old_asset->file_path;
                    $new_file_path =~ s/$q_old_site_path/$new_site_path/;
                    if ( copy_item( $old_file_path, $new_file_path ) ) {
                        my $new_asset = $old_asset->clone_all();
                        delete $new_asset->{ column_values }->{ id };
                        delete $new_asset->{ changed_cols }->{ id };
                        $new_asset->blog_id( $new_blog_id );
                        $new_asset->save or die $new_asset->errstr;
                        my $objectasset = MT->model( 'objectasset' )->new;
                        $objectasset->blog_id( $new_asset->blog_id );
                        $objectasset->asset_id( $new_asset->id );
                        $objectasset->object_ds( 'entry' );
                        $objectasset->object_id( $new_entry_id );
                        $objectasset->save or die $objectasset->errstr;
                    } else {
                        $new_object->asset_id( undef );
                    }
                } else {
                    $new_object->asset_id( undef );
                }
            }
            $new_object->save or die $new_object->errstr;
            $counter++;
        }
    }
    $callback->( $state . " " . $app->translate( "[_1] records processed.", $counter ), $state_id );
}

sub _cb_clone_blog {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'ExtFields' );
    my $elements = $tmpl->getElementsByTagName( 'unless' );
    my $obj_label = $plugin->translate( 'Extra Fields' );
    my $obj = 'extfields';
    my ( $element ) = grep { 'clone_prefs_input' eq $_->getAttribute( 'name' ) } @$elements;
    if ( $element ) {
        my $contents = $element->innerHTML;
        my $text = <<EOT;
        <input type="hidden" name="clone_prefs_${obj}" value="<mt:var name="clone_prefs_${obj}">" />
EOT
        $element->innerHTML( $contents . $text );
    }
    ( $element ) = grep { 'clone_prefs_checkbox' eq $_->getAttribute( 'name' ) } @$elements;
    if ( $element ) {
        my $contents = $element->innerHTML;
        my $text = <<EOT;
            <li>
                <input type="checkbox" name="clone_prefs_${obj}" id="clone-prefs-${obj}" <mt:if name="clone_prefs_${obj}">checked="<mt:var name="clone_prefs_${obj}">"</mt:if> class="cb" />
                <label for="clone-prefs-${obj}"><__trans_section component="ExtFields"><__trans phrase="${obj_label}"></__trans_section></label>
            </li>
EOT
        $element->innerHTML( $contents . $text );
    }
    ( $element ) = grep { 'clone_prefs_exclude' eq $_->getAttribute( 'name' ) } @$elements;
    if ( $element ) {
        my $contents = $element->innerHTML;
        my $text = <<EOT;
<mt:if name="clone_prefs_${obj}" eq="on">
            <li><__trans_section component="ExtFields"><__trans phrase="Exclude ExtFields"></__trans_section></li>
</mt:if>
EOT
        $element->innerHTML( $contents . $text );
    }
}

sub _parse_asset {
    my ( $app, $blog, $obj, $text, $original_text, $textformat, $rel2abs, $doc_root, $site_path, $site_url, $dir ) = @_;
    my $abs_path = $site_url;
    $abs_path =~ s/https*:\/\/.*?(\/.*$)/$1/;
    $abs_path = quotemeta( $abs_path );
    my $match = '<[^>]+\s(src|href|action)\s*=\s*\"';
    my @org_asset; my @save_asset;
    if ( defined $original_text ) {
        $original_text =~ s/($match)(.{1,}?)(")/$1.SidebarAssets::Plugin::_check_asset(
                     $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                     $doc_root, 0, \@org_asset, \@save_asset
                 ).$4/esg;
    }
    my $text_before = $text;
    $text =~ s/($match)(.{1,}?)(")/$1.SidebarAssets::Plugin::_check_asset(
                 $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                 $doc_root, 1, \@org_asset, \@save_asset
             ).$4/esg;
    if ( defined $original_text ) {
        for my $objectasset ( @org_asset ) {
            my $oid = $objectasset->id;
            unless ( grep( /^$oid$/, @save_asset ) ) {
                $objectasset->remove or die $objectasset->errstr;
            }
        }
    }
    if ( ( $textformat eq '9' && $rel2abs == 1 ) || $rel2abs == 2 ) {
        if ( $original_text ne $text ) {
            return $text;
        }
    }
    return $text_before;
    1;
}

sub _save_extras {
    my ( $eh, $app, $obj, $original ) = @_;
    return 1 if is_power_edit( $app );
    my $plugin = MT->component( 'ExtFields' );
    my $user = current_user( $app );
    my $blog = $app->blog;
    my $blog_id = $blog->id;
    my $fmgr = $blog->file_mgr;
    my $q = $app->param;
    my $fld_names = $q->param( 'newFldNames' );
    my $new_entry = $q->param( 'newentry' );
    my $entry_id = $obj->id;
    my @extras = split( /\,/, $fld_names );
    my @tmp_flds;
    for my $flditem ( @extras ) {
        if ( ! ( grep( /$flditem/, @tmp_flds ) ) ) {
            push ( @tmp_flds, $flditem );
        }
    }
    @extras = @tmp_flds;
    my $count = scalar @extras;
    my @new_flds;
    my $site_path = site_path( $blog );
    my $backslash2slash;
    if ( is_windows() ) {
        if ( $site_path =~ m!/! ) {
            $backslash2slash = 1;
        }
    }
    if ( is_windows() ) {
        $site_path =~ s!/!\\!g;
    }
    my $site_url = site_url( $blog );
    $site_url =~ s/(.*)\/$/$1/;
    my $q_site_path = quotemeta( $site_path );
    my $enable_upload = $plugin->get_config_value( 'enable_upload' );
    $enable_upload = lc( $enable_upload );
    my @ext_check = split( /,/, $enable_upload );
    my $upload_path = $plugin->get_config_value( 'upload_path' );
    if ( $upload_path =~ /%u/ ) {
        my $uname = $user->name;
        $uname =~ s/\s/_/g;
        $upload_path =~ s/%u/$uname/g;
    }
    if ( $upload_path =~ /%i/ ) {
        my $uid = $user->id;
        $upload_path =~ s/%i/$uid/g;
    }
    if ( $upload_path =~ /(.*)\/$/ ) {
        $upload_path = $1;
    }
    # for _parse_asset
    my $abs_path = $site_url;
    $abs_path =~ s/https*:\/\/.*?(\/.*$)/$1/;
    $abs_path = quotemeta( $abs_path );
    my $doc_root = $site_path;
    $doc_root =~ s/$abs_path$//;
    $doc_root =~ s/(.*)\/$/$1/;
    if ( is_windows() ) {
        $doc_root =~ s/(.*)\\$/$1/;
    }
    my $file = $obj->archive_file();
    $file = File::Spec->catfile( $site_path, $file );
    my $dir = File::Basename::dirname( $file );
    my $sidebarassets = MT->component( 'SidebarAssets' );
    my $scope = 'blog:' . $blog->id;
    my $rel2abs = $sidebarassets->get_config_value( 'rel2abs', $scope );
    my $ext_datas; my $ext_files;
    for ( 1 .. $count ) {
        my $name = $extras[ $_ - 1 ];
        my $text; my $compact;
        my $label = $name . '-label';
        my $org_name = $name;
        $label = $q->param( $label );
        if ( $label && ! ( grep { my $search = quotemeta( $name ); $_ =~ /$search/; } @new_flds ) ) {
            my $type = $1 if { $name =~ /^.*\-[0-9]{1,}\-(.*$)/ };
            if ( $type eq 'file_compact' ) {
                $type = 'file';
                $compact = 1;
            }
            my $multiple; my $select_item; my $file_path;
            my $alternative; my $description; my $textformat;
            if ( $type eq 'radio' || $type eq 'select' || $type eq 'cbgroup' ) {
                $multiple = $q->param( $name . '-multiple' );
                if ( $type eq 'cbgroup' ) {
                    my @multi_vals = split( /,/, $multiple );
                    my $j = 1;
                    for my $m_val ( @multi_vals ) {
                        my $q_val = $q->param( $name . $j );
                        if ( $q_val ) {
                            if ( $text ) {
                                $text .= ',' . $m_val;
                            } else {
                                $text = $m_val;
                            }
                        }
                        $j++;
                    }
                }
            }
            if ( $type eq 'checkbox' ) {
                $select_item = $q->param( $name . '-select_item' );
            }
            if ( $type eq 'file' ) {
                $file_path = $q->param( $name . '-filepath' );
                $file_path = encode_url( $file_path );
                $file_path =~ s/%2F/\//g;
                $file_path =~ s/\.\.//g;
                if ( is_windows() ) {
                    $file_path =~ s/\//\\/g;
                    $upload_path =~ s/\//\\/g;
                }
                $alternative = $q->param( $name . '-alttext' );
                $description = $q->param( $name . '-desctext' );
                unless ( $alternative ) {
                    my $FH = $q->upload( $org_name );
                    if ( $FH ) {
                        if ( is_image( $org_name ) ) {
                            require MT::Image;
                            if (! MT::Image::is_valid_image( $FH ) ) {
                                close ( $FH );
                                next;
                            }
                        }
                    }
                    if ( $FH ) {
                        if ( ExtFields::Util::can_upload( $FH, @ext_check ) ) {
                            $alternative = file_basename( $FH );
                        }
                    }
                }
                $ext_datas .= "$alternative\n$description\n";
            } else {
                unless ( $type eq 'cbgroup' ) {
                    $text = $q->param( $name );
                }
                if ( $type eq 'text' || $type eq 'date' || $type eq 'textarea' ) {
                    if ( $type eq 'date' ) {
                        my $time = $q->param( $name . '-time' );
                        $time =~ s/://g;
                        $time =~ s/\-//g;
                        $time =~ s/\s//g;
                        if ( $time !~ /^[0-9]{1,}$/ ) {
                            $time = '000000';
                        }
                        $text .= $time;
                        $text =~ s/\-//g;
                        $text =~ s/://g;
                        $text =~ s/\s//g;
                        if ( $text !~ /^[0-9]{1,}$/ ) {
                            my @tl = offset_time_list( time, $blog );
                            $text = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
                        } else {
                            $text .= '000000000000';
                            $text = substr( $text, 0, 14 );
                        }
                    } else {
                        $ext_datas .= "$text\n";
                    }
                }
            }
            if ( $type eq 'textarea' || $type eq 'file' ) {
                $textformat = $q->param( $name . '-textformat' );
            }
            $name = $1 if { $name =~ /(^.*\-[0-9]{1,})\-.*$/ };
            push ( @new_flds, $name);
            my $fname; my $full_path; my $asset_path; my $asset_id;
            my $FH; my $file; my $overwrite; my $asset; my $ext;
            my $filename; my $mime_type; my $asset_type;
            my $thumb_w; my $thumb_h; my $newthumb;
            my $globe_x; my $globe_y; my $is_image; my $is_video; my $is_audio;
            my $saved_asset; my $image_type; my $entry_asset_id; my $ext_added;
            if ( $type eq 'file' ) {
                $FH = $q->upload( $org_name );
                if ( $FH ) {
                    if ( is_image( $org_name ) ) {
                        require MT::Image;
                        if (! MT::Image::is_valid_image( $FH ) ) {
                            close ( $FH );
                            next;
                        }
                    }
                }
                my $local_basename; my $can_upload;
                if ( $FH ) {
                    $can_upload = ExtFields::Util::can_upload( $FH, @ext_check );
                    unless ( $can_upload ) {
                        $FH = '';
                    }
                }
                my $replace = $q->param( $name . '-file-replace' );
                if ( $FH && $can_upload ) {
                    if ( $replace && $FH ) {
                        my $replace_path = $q->param( $name . '-file-fullpath' );
                        my $replace_obj = MT->model( 'asset' )->load( { blog_id => $blog->id,
                                                                        class => '*',
                                                                        url => $replace_path,
                                                                      }
                                                                    );
                        if ( defined $replace_obj ) {
                            my @rep_asset = MT->model( 'extfields' )->load( { text => $replace_path,
                                                                              status => 1,
                                                                            }
                                                                          );
                            if ( ( scalar @rep_asset ) < 2 && defined $original ) {
                                my $replace_obj_id = $replace_obj->id;
                                $replace_obj->remove
                                            or return $app->trans_error( 'Error removing asset: [_1]', $replace_obj->errstr );
                                my @children = MT->model( 'asset' )->load( { class => '*',
                                                                             parent => $replace_obj_id,
                                                                           }
                                                                         );
                                for my $child ( @children ) {
                                    next unless defined $child;
                                    $child->remove
                                        or return $app->trans_error( 'Error removing asset: [_1]', $child->errstr );
                                }
                            }
                        }
                    }
                    my $file_info = $q->uploadInfo( $FH );
                    if ( $file_info ) {
                        $mime_type = $file_info->{ 'Content-Type' };
                    }
                    $fname = $FH;
                    unless ( $alternative ) {
                        $alternative = file_basename( $fname );
                    }
                    $fname = MT->config( 'NoDecodeFilename' ) ? file_basename( $fname ) : set_upload_filename( $fname );
                    my $site_path = site_path( $blog );
                    $full_path = File::Spec->catfile( $site_path, $upload_path, $file_path );
                    $file = File::Spec->catfile( $full_path, $fname );
                    if ( charset_is_utf8() ) { # TODO: go to Util.pm
                        $file = Encode::decode_utf8( $file );
                        $fname = Encode::decode_utf8( $fname );
                        $alternative = Encode::decode_utf8( $alternative ) unless Encode::is_utf8( $alternative );
                    }
                    if ( $file_path ) {
                        $asset_path = File::Spec->catfile( '%r', $upload_path, $file_path, $fname );
                    } else {
                        $asset_path = File::Spec->catfile( '%r', $upload_path, $fname );
                    }
                    my $path = dirname( $file );
                    $path =~ s!/$!! unless $path eq '/';
                    unless ( $fmgr->exists( $path ) ) {
                        $fmgr->mkpath( $path );
                    }
                    my $temp_file = "$file.new";
                    local *OUT;
                    my $umask = $app->config( 'UploadUmask' );
                    my $old = umask( oct $umask );
                    open OUT, ">$temp_file" || die "Can't open $temp_file!";
                    binmode OUT;
                    while ( read( $FH, my $buffer, 1024 ) ){
                        print OUT $buffer;
                    }
                    close ( OUT );
                    close ( $FH );
                    $overwrite = $q->param( $org_name . '-overwrite' );
                    if ( $fmgr->exists( $file ) && $overwrite eq 'rename' ) {
                        $file = uniq_filename( $file, { no_decode => 1, } );
                        $asset_path = $file;
                        $asset_path =~ s/$q_site_path/%r/;
                    }
                    $local_basename = file_basename( $file );
                    move_file( $temp_file, $file );
                    umask( $old );
                } else {
                    $mime_type = $q->param( $org_name . '-mimetype' );
                    $asset_path = $q->param( $org_name . '-fullpath' );
                    if ( $q->param( $org_name . '-fullpath-replace' ) ) {
                        $asset_path = $q->param( $org_name . '-fullpath-replace' );
                        $mime_type = $q->param( $org_name . '-mimetype-replace' );
                    }
                    $file = $asset_path;
                    my $asset_obj = MT->model( 'asset' )->load( { file_path => $asset_path,
                                                                  class => '*',
                                                                  blog_id => $blog_id
                                                                },
                                                              );
                    if ( $asset_obj ) {
                        $entry_asset_id = $asset_obj->id;
                        $asset_id = $asset_obj->id;
                        my $objectasset = MT->model( 'objectasset' )->get_by_key( { asset_id => $asset_obj->id,
                                                                                    object_id => $entry_id,
                                                                                    object_ds => 'entry',
                                                                                    blog_id => $blog_id,
                                                                                  },
                                                                                );
                        unless ( $objectasset->id ) {
                            $objectasset->save
                                    or return $app->trans_error( 'Error saving objectasset: [_1]', $objectasset->errstr );
                        }
                    }
                    $file =~ s/%r/$site_path/;
                    if ( $file ) {
                        $local_basename = file_basename( $file );
                    }
                }
                if ( ( $FH || ( $new_entry && $file ) || $q->param( 'duplicate' ) )
                     && $asset_path
                ) {
                    my @suffix = split( /\./, $asset_path );
                    $ext = pop( @suffix );
                    unless ( $ext_files ) {
                        $ext_files = $ext;
                    } else {
                        $ext_files .= ',' . $ext;
                    }
                    $ext_added = 1;
                    $filename = file_basename( $asset_path );
                    my $asset_pkg;
                    if ( $local_basename ) {
                        $asset_pkg = MT->model( 'asset' )->handler_for_file( $local_basename );
                        if ( $ext =~ /^jpe?g$/i || $ext =~ /^gif$/i || $ext =~ /^png$/i ) {
                            $is_image = 1;
                            $asset_pkg->isa( 'MT::Asset::Image' );
                            if ( $ext =~ /^jpe?g$/i ) {
                                $image_type = 'JPG';
                            } else {
                                $image_type = uc( $ext );
                            }
                        } elsif ( $ext =~ /^mov$/i || $ext =~ /^avi$/i || $ext =~ /^3gp$/i ||
                                  $ext =~ /^asf$/i || $ext =~ /^mp4$/i || $ext =~ /^qt$/i ||
                                  $ext =~ /^wmv$/i || $ext =~ /^asx$/i || $ext =~ /^mpg$/i
                        ) {
                            $asset_pkg->isa( 'MT::Asset::Video' );
                            $is_video = 1;
                        } elsif ( $ext =~ /^mp3$/i || $ext =~ /^ogg$/i || $ext =~ /^aiff?$/i ||
                                  $ext =~ /^wav$/i || $ext =~ /^wma$/i || $ext =~ /^aac$/i
                        ) {
                            $asset_pkg->isa( 'MT::Asset::Audio' );
                            $is_audio = 1;
                        }
                    }
                    my $asset = $asset_pkg->load( { file_path => $asset_path,
                                                    blog_id => $blog_id,
                                                  },
                                                );
                    my $new_asset;
                    unless ( defined $asset ) {
                        $asset = $asset_pkg->new();
                        $new_asset = 1;
                    }
                    unless ( defined $asset ) { # TODO: is not used?
                        $asset = MT->model( 'asset' )->load( { class => '*', url => $asset_path } );
                        if ( defined $asset ) {
                            $new_asset = 0;
                        } else {
                            $asset = MT->model( 'asset' )->new;
                            $new_asset = 1;
                        }
                    }
                    $asset->blog_id( $blog_id );
                    if ( $backslash2slash ) {
                        $asset_path =~ s!\\!/!g;
                    }
                    $asset->file_path( $asset_path );
                    my $asset_url = $asset_path;
                    $asset_url =~ s/\\/\//g;
                    $asset->url( $asset_url );
                    $asset->file_name( $filename );
                    $asset->mime_type( $mime_type );
                    $asset->file_ext( $ext );
                    $asset->created_by( $user->id );
                    if ( $is_image ) {
                        $asset_type = 'image';
                        my $thumb_width = $plugin->get_config_value( 'thumb_width' );
                        ( $globe_x, $globe_y) = imgsize( $file );
                        my $thumb_path = $q->param( $org_name . '-thumbnailpath' );
                        if ( $q->param( $org_name . '-thumbnailpath-replace' ) ) {
                            $thumb_path = $q->param( $org_name . '-thumbnailpath-replace' );
                        }
                        $thumb_path =~ s/%r/$site_path/;
                        if ( ! $thumb_path || ( $replace && $FH ) ) {
                            if ( $thumb_width < $globe_x ) {
                                my $tumbfile = $file;
                                $tumbfile =~ s/(^.*)\..*$/$1-thumb.$ext/;
                                if ( $fmgr->exists( $tumbfile ) && $overwrite eq 'rename' ) {
                                    $tumbfile = uniq_filename( $tumbfile );
                                }
                                my $img = MT::Image->new( Filename => $file );
                                my ( $blob, $w, $h ) = $img->scale( Width => $thumb_width );
                                local *FH;
                                my $umask = $app->config( 'UploadUmask' );
                                my $old = umask( oct $umask );
                                open FH, "> $tumbfile" || die "Can't create $tumbfile!";
                                binmode FH;
                                print FH $blob;
                                close FH;
                                ( $thumb_w, $thumb_h ) = imgsize( $tumbfile );
                                $newthumb = $tumbfile;
                                $newthumb =~ s/(^.*)\..*$/$1.$thumb_w.'x'.$thumb_h.'.'.$ext/e;
                                $fmgr->rename( $tumbfile, $newthumb );
                                umask( $old );
                            }
                        } else {
                            $newthumb = $thumb_path;
                            ( $thumb_w,$thumb_h ) = imgsize( $newthumb );
                        }
                    } elsif ( $is_video ) {
                        $asset_type = 'video';
                    } elsif ( $is_audio ) {
                        $asset_type = 'audio';
                    } else {
                        $asset_type = 'file';
                    }
                    $asset->class( $asset_type );
                    $asset->label( $alternative );
                    $asset->description( $description );
                    if ( $is_image ) {
                        $asset->image_width( $globe_x );
                        $asset->image_height( $globe_y );
                    }
                    $asset->save
                            or return $app->trans_error( 'Error saving asset: [_1]', $asset->errstr );
                    $entry_asset_id = $asset->id;
                    my @fdatas = stat( $file );
                    my $bytes = $fdatas[ 7 ];
                    my $full_url = $asset_url;
                    $full_url =~ s/%r/$site_url/;
                    upload_callback( $app, $file, $full_url, $bytes, $asset, $blog, $globe_y, $globe_x, $image_type, $is_image );
                    $saved_asset = 1;
                    $asset_id = $asset->id;
                    my %param = $app->param_hash;
                    $param{ id } = $asset_id;
                    $asset->on_upload( \%param );
                }
            }
            my $extfields = MT->model( 'extfields' )->load( { entry_id => $entry_id,
                                                              name => $name,
                                                            },
                                                          );
            unless ( defined $extfields ) {
                $extfields = MT->model( 'extfields' )->new;
            }
            $extfields->blog_id( $blog_id );
            $extfields->entry_id( $entry_id );
            $extfields->name( $name );
            if ( $asset_id ) {
                if ( $extfields->asset_id && $extfields->asset_id != $asset_id ) {
                    my $objectasset = MT->model( 'objectasset' )->load( { asset_id => $extfields->asset_id,
                                                                          object_ds => 'entry',
                                                                          object_id => $entry_id,
                                                                        },
                                                                      );
                    if ( defined $objectasset ) {
                        $objectasset->remove or die $objectasset->errstr;
                    }
                }
                $extfields->asset_id( $asset_id );
            }
            if ( $type eq 'file' ) {
                my $delete = $q->param( $org_name . '-delete' );
                $asset_path = $q->param( $org_name . '-fullpath' );
                if ( $q->param( $org_name . '-fullpath-replace' ) ) {
                    $asset_path = $q->param( $org_name . '-fullpath-replace' );
                }
                unless ( $FH || ( $new_entry && $asset_path ) ) {
                    $file = $asset_path;
                    $file =~ s/%r/$site_path/;
                    if ( $fmgr->exists( $file ) && $is_image ) {
                        ( $globe_x, $globe_y ) = imgsize( $file );
                        $extfields->metadata( "$globe_x,$globe_y" );
                        $asset_type = 'image';
                    }
                } else {
                    if ( $newthumb ) {
                        my $thumb_basename = File::Basename::basename( $newthumb );
                        my $thumb_asset_pkg = MT->model( 'asset' )->handler_for_file( $thumb_basename );
                        $thumb_asset_pkg->isa( 'MT::Asset::Image' );
                        my $newthumb_asset = $newthumb;
                        $newthumb_asset =~ s/$q_site_path/%r/;
                        if ( $backslash2slash ) {
                            $newthumb_asset =~ s!\\!/!g;
                        }
                        my $thumb_asset = $thumb_asset_pkg->load( { file_path => $newthumb_asset,
                                                                    blog_id => $blog_id,
                                                                  }
                                                                );
                        unless ( defined $thumb_asset ) {
                            $thumb_asset = $thumb_asset_pkg->new();
                        }
                        unless ( defined $thumb_asset ) { # TODO: is not used?
                            $thumb_asset = MT->model( 'asset' )->load( { class => '*', url => $newthumb } );
                            unless ( defined $thumb_asset ) {
                                $thumb_asset = MT->model( 'asset' )->new;
                            }
                        }
                        if ( is_windows() ) {
                            my $newthumb_asset_win = $newthumb_asset;
                            $newthumb_asset_win =~ s/\\/\//g;
                            if ( $backslash2slash ) {
                                $newthumb_asset_win =~ s!\\!/!g;
                            }
                            $extfields->thumbnail( $newthumb_asset_win );
                        } else {
                            $extfields->thumbnail( $newthumb_asset );
                        }
                        if ( $backslash2slash ) {
                            $newthumb_asset =~ s!\\!/!g;
                        }
                        $thumb_asset->blog_id( $blog_id );
                        $thumb_asset->file_path( $newthumb_asset );
                        my $newthumb_asset_url = $newthumb_asset;
                        if ( is_windows() ) {
                            $newthumb_asset_url =~ s/\\/\//g;
                        }
                        $thumb_asset->url( $newthumb_asset_url );
                        my $thumbname = file_basename( $newthumb );
                        $thumb_asset->file_name( $thumbname );
                        $thumb_asset->mime_type( $mime_type );
                        $thumb_asset->file_ext( $ext );
                        $thumb_asset->created_by( $app->user->id );
                        $thumb_asset->class( $asset_type );
                        my $thmb_alt;
                        if ( $alternative ) {
                            $thmb_alt = $alternative . $plugin->translate( ' Thumbnail' );
                        } else {
                            $thmb_alt = $filename . $plugin->translate( ' Thumbnail' );
                        }
                        $thumb_asset->label( $thmb_alt );
                        $thumb_asset->image_width( $thumb_w );
                        $thumb_asset->image_height( $thumb_h );
                        $thumb_asset->description( $description );
                        $thumb_asset->parent( $asset_id );
                        $thumb_asset->save
                                or return $app->trans_error( 'Error saving asset: [_1]', $asset->errstr );
                        my @fdatas = stat( $newthumb );
                        my $bytes = $fdatas[ 7 ];
                        my $full_url = $newthumb_asset_url;
                        $full_url =~ s/%r/$site_url/;
                        upload_callback( $app, $newthumb, $full_url, $bytes, $thumb_asset, $blog, $thumb_h, $thumb_w, $image_type, $is_image );
                        $extfields->thumb_metadata( "$thumb_w,$thumb_h" );
                    }
                }
                unless ( $delete ) {
                    my $asset_path = $file;
                    $asset_path =~ s/$q_site_path/%r/;
                    my $asset_url = $asset_path;
                    $asset_url =~ s/\\/\//g;
                    $extfields->text( $asset_url );
                    $extfields->file_path( $file_path );
                    $extfields->alternative( $alternative );
                    $description = _parse_asset( $app, $blog, $obj, $description, $extfields->description, $textformat, $rel2abs, $doc_root, $site_path, $site_url, $dir );
                    $extfields->description( $description );
                    if ( $fmgr->exists( $file ) ) {
                        if ( $asset_type eq 'image' ) {
                            $extfields->metadata( "$globe_x,$globe_y" );
                            $extfields->file_type( 'image' );
                        } elsif ( $asset_type eq 'video' ) {
                            $extfields->file_type( 'video' );
                        } elsif ( $asset_type eq 'audio' ) {
                            $extfields->file_type( 'audio' );
                        } else {
                            $extfields->file_type( 'file' );
                        }
                        if ( $asset_type ne 'image' ) {
                            $extfields->metadata( undef );
                            $extfields->thumb_metadata( undef );
                            $extfields->thumbnail( undef );
                        }
                    }
                } else {
                    my $orig_asset_id = $extfields->asset_id;
                    $extfields->text( undef );
                    $extfields->asset_id( undef );
                    $extfields->metadata( undef );
                    $extfields->file_type( undef );
                    $extfields->mime_type( undef );
                    $extfields->thumbnail( undef );
                    $extfields->thumb_metadata( undef );
                    $mime_type = undef;
                    $extfields->alternative( $alternative );
                    $description = _parse_asset( $app, $blog, $obj, $description, $extfields->description, $textformat, $rel2abs, $doc_root, $site_path, $site_url, $dir );
                    $extfields->description( $description );
                    if ( $fmgr->exists( $file ) ) {
                        my $asset_path = $file;
                        $asset_path =~ s/$q_site_path/%r/;
                        my $check_asset = $asset_path;
                        if ( is_windows() ) {
                            $check_asset =~ s/\\/\//g;
                        }
                        my @same_asset = MT->model( 'extfields' )->load( { text => $check_asset, status => 1 } );
                        my $asset_id = $orig_asset_id;
                        if ( ( scalar @same_asset ) < 2 ) {
                            if ( $asset_id ) {
                                my $oacount = _count_objectasset( $asset_id, $entry_id );
                                unless ( $oacount ) {
                                    my $asset = MT->model( 'asset' )->load( { id => $asset_id } );
                                    if ( defined $asset ) {
                                        $asset->remove
                                            or return $app->trans_error( 'Error removing asset: [_1]', $asset->errstr );
                                    }
                                }
                            }
                        }
                        my $objectasset = MT->model( 'objectasset' )->load( { asset_id => $asset_id,
                                                                              object_ds => 'entry',
                                                                              object_id => $entry_id,
                                                                            }
                                                                          );
                        if ( defined $objectasset ) {
                            $objectasset->remove or die $objectasset->errstr;
                        }
                    }
                }
            } else {
                if ( $type eq 'textarea' ) {
                    $text = _parse_asset( $app, $blog, $obj, $text, $extfields->text, $textformat, $rel2abs, $doc_root, $site_path, $site_url, $dir );
                }
                $extfields->text( $text );
            }
            if ( $type eq 'file' && $extfields->file_type eq 'file' ) {
                my $check_ext = $extfields->text;
                my @suffix = split( /\./, $check_ext );
                my $ext = pop( @suffix );
                if ( $ext =~ /^jpe?g$/i || $ext =~ /^gif$/i || $ext =~ /^png$/i ) {
                    $extfields->file_type( 'image' );
                } elsif ( $ext =~ /^mov$/i || $ext =~ /^avi$/i || $ext =~ /^3gp$/i ||
                          $ext =~ /^asf$/i || $ext =~ /^mp4$/i || $ext =~ /^qt$/i ||
                          $ext =~ /^wmv$/i || $ext =~ /^asx$/i || $ext =~ /^mpg$/i
                ) {
                    $extfields->file_type( 'video' );
                } elsif ( $ext =~ /^mp3$/i || $ext =~ /^ogg$/i || $ext =~ /^aiff?$/i ||
                          $ext =~ /^wav$/i || $ext =~ /^wma$/i || $ext =~ /^aac$/i
                ) {
                    $extfields->file_type( 'audio' );
                }
                unless ( $ext_added ) {
                    $ext_files .= $ext_files ? ( ',' . $ext ) : $ext;
                }
            }
            $extfields->label( $label );
            $extfields->multiple( $multiple );
            $extfields->select_item( $select_item );
            $extfields->type( $type );
            $extfields->compact( $compact );
            $extfields->transform( $textformat );
            $extfields->mime_type( $mime_type );
            $extfields->sort_num( $_ );
            $extfields->status( 1 );
            $extfields->save
                or return $app->trans_error( 'Error saving extras: [_1]', $extfields->errstr );
            unless ( $saved_asset ) {
                my $asset = MT->model( 'asset' )->load( { id => $extfields->asset_id } );
                if ( defined $asset ) {
                    $entry_asset_id = $asset->id;
                }
            }
            if ( $entry_asset_id ) {
                my $objectasset = MT->model( 'objectasset' )->get_by_key( { asset_id => $entry_asset_id,
                                                                            object_id => $obj->id,
                                                                            object_ds => 'entry',
                                                                            blog_id => $blog_id
                                                                          }
                                                                        );
                $objectasset->save
                        or return $app->trans_error( 'Error saving objectasset: [_1]', $objectasset->errstr );
            }
        }
    }
    if ( scalar @new_flds ) {
        my @extras = MT->model( 'extfields' )->load( { entry_id => $entry_id,
                                                       status => 1,
                                                     }
                                                   );
        if ( @extras ) {
            for my $extfields ( @extras ) {
                my $name = $extfields->name;
                unless ( grep( /^$name$/, @new_flds ) ) {
                    if ( $extfields->type eq 'file' ) {
                        my $rem_file = $extfields->text;
                        $rem_file =~ s/%r/$site_path/;
                        my $check_asset = $rem_file;
                        if ( is_windows() ) {
                            $check_asset =~ s/\\/\//g;
                        }
                        my @same_asset = MT->model( 'extfields' )->load( { text => $check_asset, status => 1 } );
                        if ( ( scalar @same_asset ) < 2 ) {
                            my $asset_id = $extfields->asset_id;
                            if ( $extfields->asset_id ) {
                                my $oacount = _count_objectasset( $asset_id, $entry_id );
                                unless ( $oacount ) {
                                    my $asset = MT->model( 'asset' )->load( { id => $asset_id } );
                                    if ( defined $asset ) {
                                        $asset->remove
                                            or return $app->trans_error( 'Error removing asset: [_1]', $asset->errstr );
                                        my $child = MT->model( 'asset' )->load( { class => '*', parent => $asset_id } );
                                        if ( defined $child ) {
                                            $child->remove
                                                or return $app->trans_error( 'Error removing asset: [_1]', $child->errstr );
                                        }
                                    }
                                }
                            }
                        }
                    }
                    $extfields->remove
                        or return $app->trans_error( 'Error removing extras: [_1]', $extfields->errstr );
                }
            }
        }
    }
    unless ( $fld_names ) {
        my @extras = MT->model( 'extfields' )->load( { entry_id => $entry_id } );
        if ( @extras ) {
            for my $extfields ( @extras ) {
                if ( $extfields->type eq 'file' ) {
                    my $asset_id = $extfields->asset_id;
                    if ( $extfields->asset_id ) {
                        my $asset = MT->model( 'asset' )->load( { id => $asset_id } );
                        if ( $asset ) {
                            my $oacount = _count_objectasset( $asset_id, $entry_id );
                            unless ( $oacount ) {
                                $asset->remove
                                    or return $app->trans_error( 'Error removing asset: [_1]', $asset->errstr );
                            }
                        }
                    }
                }
                $extfields->remove
                        or return $app->trans_error( 'Error removing extras: [_1]', $extfields->errstr );
            }
        }
    }
    my $meta = {}; my $custom_datas;
    if ( $q->param( 'customfield_beacon' ) ) {
        foreach ( $q->param() ) {
            next if $_ eq 'customfield_beacon';
            if ( m/^customfield_(.*?)$/ ) {
                my $field_name = $1;
                if ( m/^customfield_(.+?)_cb_beacon$/ ) {
                    $field_name = $1;
                    $meta->{ $field_name} = defined( $q->param( "customfield_$field_name" ) )
                      ? $q->param( "customfield_$field_name" )
                      : '0';
                }
                else {
                    $meta->{ $field_name } =
                        $q->param( "customfield_$field_name" ) ne ''
                      ? $q->param( "customfield_$field_name" )
                      : undef;
                }
                $custom_datas .= $meta->{ $field_name } . "\n";
            }
        }
    }
    $ext_datas .= $custom_datas;
    $obj->ext_datas( $ext_datas );
    $obj->ext_files( $ext_files );
1;
}

sub _count_objectasset {
    my ( $asset_id, $entry_id ) = @_;
    my $oacount = MT->model( 'objectasset' )->count( { asset_id => $asset_id,
                                                       object_ds => 'entry',
                                                       object_id => { not => $entry_id },
                                                     }
                                                   );
    unless ( $oacount ) { # TODO: Why? It should be contained.
        $oacount = MT->model( 'objectasset' )->count( { asset_id => $asset_id,
                                                        object_ds => { not => 'entry' },
                                                      }
                                                    );
    }
    return $oacount;
}

#no warnings 'redifine';
sub _remove_extras {
    my ( $eh, $app, $obj ) = @_;
    my $blog = $app->blog;
    unless ( defined $blog ) {
        $blog = MT::Blog->load( { id => $obj->blog_id } );
    }
    my @extras = MT->model( 'extfields' )->load( { entry_id => $obj->id } );
    for my $extfields ( @extras ) {
        if ( $extfields->type eq 'file' ) {
            if ( my $asset_id = $extfields->asset_id ) {
                my $asset = MT->model( 'asset' )->load( { id => $asset_id } );
                if ( $asset ) {
                    my $relation = MT->model( 'objectasset' )->count( { object_ds => 'entry',
                                                                        blog_id => $obj->blog_id,
                                                                        asset_id => $asset_id,
                                                                      },
                                                                    );
                    unless ( $relation ) {
                        $asset->remove
                            or return $app->trans_error( 'Error removing asset: [_1]', $asset->errstr );
                    }
                }
            }
        }
        $extfields->remove
            or return $app->trans_error( 'Error removing extras: [_1]', $extfields->errstr );
    }
1;
}

sub _extfield_param {
    my ( $cb, $app, $param ) = @_;
    for my $key ( $app->param ) {
        if ( $key =~ /^extfields\-/ ) {
            my $input = { 'data_name' => $key,
                          'data_value' => $app->param( $key ),
                        };
            push( @{ $param->{ 'entry_loop' } }, $input );
        }
    }
    my $fld_names = $app->param( 'newFldNames' );
    my @extras = split( /\,/, $fld_names );
    my @tmp_flds;
    $fld_names = '';
    for my $flditem ( @extras ) {
        if ( ! grep { my $search = quotemeta( $flditem ); $_ =~ /$search/; } @tmp_flds ) {
            push ( @tmp_flds, $flditem );
            $fld_names .= $flditem ? ( ',' . $flditem ) : $flditem;
        }
    }
    if ( $fld_names ) {
        my $input = { 'data_name' => 'newFldNames',
                      'data_value' => $fld_names,
                    };
        push( @{ $param->{ 'entry_loop' } }, $input );
    }
    if ( my $fld_count = $app->param( 'newFldCount' ) ) {
        my $input = { 'data_name' => 'newFldCount',
                      'data_value' => $fld_count,
                    };
        push( @{ $param->{ 'entry_loop'} }, $input );
    }
1;
}

sub _preview_param {
    my ( $eh, $app, $param ) = @_;
    my $plugin = MT->component( 'ExtFields' );
    my $user = current_user( $app );
    my $q = $app->param;
    my $blog = $app->blog;
    my $blog_id = $blog->id;
    my $fmgr = $blog->file_mgr;
    my $site_path = site_path( $blog );
    if ( is_windows() ) {
        $site_path =~ s!/!\\!g;
    }
    my $site_url = site_url( $blog );
    $site_url =~ s/(.*)\/$/$1/;
    my $upload_path = $plugin->get_config_value( 'upload_path' );
    if ( $upload_path =~ /%u/ ) {
        my $uname = $app->user->name;
        $uname =~ s/\s/_/g;
        $upload_path =~ s/%u/$uname/g;
    }
    if ( $upload_path =~ /%i/ ) {
        my $uid = $user->id;
        $upload_path =~ s/%i/$uid/g;
    }
    $upload_path =~ s/(.*)\/$/$1/;
    my $q_site_path = quotemeta( $site_path );
    my $enable_upload = $plugin->get_config_value( 'enable_upload' );
    $enable_upload = lc( $enable_upload );
    my @ext_check = split( /,/, $enable_upload );
    my $entry_id = $q->param( 'id' );
    unless ( $entry_id ) {
        $entry_id = -1;
        my @extras = MT->model( 'extfields' )->load( { entry_id => -1 } );
        for my $extfields ( @extras ) {
            $extfields->remove
                or return $app->trans_error( 'Error cleanup extras: [_1]', $extfields->errstr );
        }
    } else {
        my @extras = MT->model( 'extfields' )->load( { entry_id => $entry_id } );
        if ( @extras ) {
            for my $extfields ( @extras ) {
                $extfields->status( 0 );
                $extfields->save
                        or return $app->trans_error( 'Error removing extras: [_1]', $extfields->errstr );
            }
        }
    }
    for my $key ( $q->param ) {
        if ( $key =~ /^extfields\-/ ) {
            my $input = { 'data_name' => $key,
                          'data_value' => $q->param( $key ),
                        };
            push( @{ $param->{ 'entry_loop'} }, $input );
        }
    }
    if ( $entry_id == -1 ) {
        my $input = { 'data_name' => 'newentry',
                      'data_value' => '1',
                    };
        push( @{ $param->{ 'entry_loop' } }, $input );
    }
    my $fld_names = $q->param( 'newFldNames' );
    if ( $fld_names ) {
        my $input = { 'data_name' => 'newFldNames',
                      'data_value' => $fld_names,
                    };
        push( @{ $param->{ 'entry_loop' } }, $input );
    }
    my $fld_count = $q->param( 'newFldCount' );
    if ( $fld_count ) {
        my $input = { 'data_name' => 'newFldCount',
                      'data_value' => $fld_count,
                    };
        push( @{ $param->{ 'entry_loop' } }, $input );
    }
    my @extras = split( /\,/, $fld_names );
    my $count = scalar @extras;
    for ( 1 .. $count ) {
        my $extfields;
        my $name = $extras[ $_ - 1 ];
        my $text = $q->param( $name );
        my $org_name = $name;
        my $label = $name . '-label';
        my $label_val = $q->param( $label );
        if ( $label_val ) {
            my $type = $1 if { $name =~ /^.*\-[0-9]{1,}\-(.*$)/ };
            my $multiple; my $select_item; my $textformat;
            if ( $type eq 'date' ) {
                my $time = $q->param( $name . '-time' );
                $time =~ s/://g;
                $time =~ s/\-//g;
                $time =~ s/\s//g;
                if ( $time !~ /^[0-9]{1,}$/ ) {
                    $time = '000000';
                }
                $text .= $time;
                $text =~ s/\-//g;
                $text =~ s/://g;
                $text =~ s/\s//g;
                if ( $text !~ /^[0-9]{1,}$/ ) {
                    my @tl = offset_time_list( time, $blog );
                    $text = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
                } else {
                    $text .= '000000000000';
                    $text = substr( $text, 0, 14 );
                }
            }
            if ( $type eq 'radio' || $type eq 'select' || $type eq 'cbgroup' ) {
                $multiple = $q->param( $name . '-multiple' );
                if ( $type eq 'cbgroup' ) {
                    $text = '';
                    my @multi_vals = split( /,/, $multiple );
                    my $j = 1;
                    for my $m_val ( @multi_vals ) {
                        my $q_val = $q->param( $name . $j );
                        if ( $q_val ) {
                            $text .= $m_val ? ( ',' . $m_val ) : $m_val;
                        }
                        $j++;
                    }
                }
            }
            if ( $type eq 'checkbox' ) {
                $select_item = $q->param( $name . '-select_item' );
            }
            my $fname; my $full_path; my $asset_path; my $alternative; my $description;
            my $file_path; my $asset_id; my $thumbnailpath;
            if ( $type eq 'file' || $type eq 'file_compact' ) {
                $file_path = $q->param( $name . '-filepath' );
                $file_path = encode_url( $file_path );
                $file_path =~ s/%2F/\//g;
                $file_path =~ s/\.\.//g;
                if ( is_windows() ) {
                    $file_path =~ s/\//\\/g;
                    $upload_path =~ s/\//\\/g;
                }
                $alternative = $q->param( $name . '-alttext' );
                $description = $q->param( $name . '-desctext' );
                $thumbnailpath = $q->param( $name . '-thumbnailpath' );
            }
            if ( $type eq 'textarea' || $type eq 'file' ) {
                $textformat = $q->param( $name . '-textformat' );
            }
            my $FH; my $file; my $mime_type;
            my ( $thumb_w,$thumb_h ); my ( $globe_x, $globe_y );
            my $newthumb; my $local_basename; my $is_image; my $is_video; my $is_audio;
            my @suffix; my $ext; my $image_type; my $replaced;
            if ( $type eq 'file' || $type eq 'file_compact' ) {
                $FH = $q->upload( $name );
                if ( $FH ) {
                    if ( is_image( $name ) ) {
                        require MT::Image;
                        if (! MT::Image::is_valid_image( $FH ) ) {
                            close ( $FH );
                            next;
                        }
                    }
                }
                my $can_upload;
                if ( $FH ) {
                    $can_upload = &ExtFields::Util::can_upload($FH, @ext_check);
                    unless ( $can_upload ) {
                        $FH = '';
                    }
                }
                my $replace = $q->param( $name . '-replace' );
                if ( $FH && $can_upload ) {
                    if ( $replace ) {
                        $replaced = 1;
                        my $replace_path = $q->param( $name . '-fullpath' );
                        $thumbnailpath = '';
                    }
                    my $file_info = $q->uploadInfo( $FH );
                    if ( $file_info ) {
                        $mime_type = $file_info->{ 'Content-Type' };
                    }
                    $fname = $FH;
                    unless ( $alternative ) {
                        $alternative = file_basename( $fname );
                    }
                    $fname = ( MT->config( 'NoDecodeFilename' ) ? file_basename( $fname ) : set_upload_filename( $fname ) );
                    $full_path = File::Spec->catfile( $site_path, $upload_path, $file_path );
                    $file = File::Spec->catfile( $full_path, $fname );
                    if ( charset_is_utf8() ) {
                        $file = Encode::decode_utf8( $file );
                        $fname = Encode::decode_utf8( $fname );
                        $alternative = Encode::decode_utf8( $alternative ) unless Encode::is_utf8( $alternative );
                    }
                    if ( $file_path ) {
                        $asset_path = File::Spec->catfile( '%r', $upload_path, $file_path, $fname );
                    } else {
                        $asset_path = File::Spec->catfile( '%r', $upload_path, $fname );
                    }
                    my $path = dirname( $file );
                    $path =~ s!/$!! unless $path eq '/';
                    unless ( $fmgr->exists( $path ) ) {
                        $fmgr->mkpath( $path );
                    }
                    my $temp_file = "$file.new";
                    local *OUT;
                    my $umask = $app->config( 'UploadUmask' );
                    my $old = umask( oct $umask );
                    open ( OUT, ">$temp_file" ) || die "Can't open $temp_file!";
                    binmode ( OUT );
                    while( read( $FH, my $buffer, 1024 ) ) {
                        print OUT $buffer;
                    }
                    close ( OUT );
                    close ( $FH );
                    my $overwrite = 'rename'; #
                    if ( ( -e $file ) && ( $overwrite eq 'rename' ) ) {
                        $file = uniq_filename( $file );
                        $asset_path = $file;
                        $asset_path =~ s/$q_site_path/%r/;
                    }
                    move_file( $temp_file, $file );
                    umask( $old );
                    $local_basename = file_basename( $file );
                    @suffix = split( /\./, $asset_path );
                    $ext = pop( @suffix );
                    if ( $ext =~ /^jpe?g$/i || $ext =~ /^gif$/i || $ext =~ /^png$/i ) {
                        $is_image = 1;
                        my $thumb_width = $plugin->get_config_value( 'thumb_width' );
                        ( $globe_x, $globe_y ) = imgsize( $file );
                        if ( $thumb_width < $globe_x ) {
                            my $tumbfile = $file;
                            $tumbfile =~ s/(^.*)\..*$/$1-thumb.$ext/;
                            if ( $fmgr->exists( $tumbfile ) && $overwrite eq 'rename' ) {
                                $tumbfile = uniq_filename( $tumbfile );
                            }
                            my $img = MT::Image->new( Filename => $file );
                            my ( $blob, $w, $h ) = $img->scale( Width => $thumb_width );
                            local *FH;
                            my $umask = $app->config( 'UploadUmask' );
                            my $old = umask( oct $umask );
                            open FH, ">$tumbfile" || die "Can't create $tumbfile!";
                            binmode FH;
                            print FH $blob;
                            close FH;
                            ( $thumb_w, $thumb_h ) = imgsize( $tumbfile );
                            $newthumb = $tumbfile;
                            $newthumb =~ s/(^.*)\..*$/$1.$thumb_w.'x'.$thumb_h.'.'.$ext/e;
                            $fmgr->rename( $tumbfile, $newthumb );
                            umask( $old );
                        }
                    }
                    my $input = { 'data_name' => $name . '-fullpath',
                                  'data_value' => $asset_path,
                                };
                    push( @{ $param->{ 'entry_loop'} }, $input );
                    $input = { 'data_name' => $name . '-mimetype',
                               'data_value' => $mime_type,
                             };
                    push( @{ $param->{ 'entry_loop' } }, $input );
                    if ( $replaced ) {
                        $input = { 'data_name' => $name . '-fullpath-replace',
                                   'data_value' => $asset_path,
                                 };
                        push( @{ $param->{ 'entry_loop' } }, $input );
                        $input = { 'data_name' => $name . '-mimetype-replace',
                                   'data_value' => $mime_type,
                                 };
                        push( @{ $param->{ 'entry_loop' } }, $input );
                    }
                    if ( $newthumb ) {
                        my $newthumb_asset = $newthumb;
                        $newthumb_asset =~ s/$q_site_path/%r/;
                        $input = { 'data_name' => $name . '-thumbnailpath',
                                   'data_value' => $newthumb_asset,
                                 };
                        push( @{ $param->{ 'entry_loop' } }, $input );
                        if ( $replaced ) {
                            $input = { 'data_name' => $name . '-thumbnailpath-replace',
                                       'data_value' => $newthumb_asset,
                                     };
                            push( @{ $param->{ 'entry_loop' } }, $input );
                        }
                    } else {
                        if ( $replaced ) {
                            $input = { 'data_name' => $name . '-thumbnailpath-replace',
                                       'data_value' => '0',
                                     };
                            push( @{ $param->{ 'entry_loop'} }, $input );
                        }
                    }
                }
            }
            $name = $1 if { $name =~ /(^.*\-[0-9]{1,})\-.*$/ };
            $extfields = MT->model( 'extfields' )->new;
            $extfields->blog_id( $blog_id );
            $extfields->entry_id( $entry_id );
            $extfields->name( $name );
            if ( $type eq 'file' || $type eq 'file_compact' ) {
                my $load_extfields = MT->model( 'extfields' )->load( { entry_id => $entry_id,
                                                                       name => $name,
                                                                     }
                                                                   );
                if ( defined $load_extfields ) {
                    $extfields->id( ( $load_extfields->id ) * -1 );
                } else {
                    $extfields->id( $_ * -1 );
                }
                my $delete = $q->param( $org_name . '-delete' );
                $extfields->alternative( $alternative );
                $extfields->description( $description );
                if ( $delete ) {
                    $extfields->text( undef );
                    $extfields->file_path( undef );
                    $extfields->asset_id( undef );
                    $extfields->file_type( undef );
                    $extfields->metadata( undef );
                    $extfields->mime_type( undef );
                    $extfields->thumb_metadata( undef );
                    $extfields->thumbnail( undef );
                } else {
                    unless ( $FH ) {
                        $asset_path = $q->param( $org_name . '-fullpath' );
                        $file = $asset_path;
                        $file =~ s/%r/$site_path/;
                    }
                    my $asset_url = $asset_path;
                    $asset_url =~ s/\\/\//g;
                    $extfields->text( $asset_url );
                    $extfields->file_path( $file_path );
                    $extfields->alternative( $alternative );
                    $extfields->description( $description );
                    @suffix = split( /\./, $asset_path );
                    $ext = pop( @suffix );
                    if ( $ext =~ /^jpe?g$/i || $ext =~ /^gif$/i || $ext =~ /^png$/i ) {
                        $is_image = 1;
                        if ( $fmgr->exists( $file ) ) {
                            ( $globe_x, $globe_y ) = imgsize( $file );
                            $extfields->metadata( "$globe_x,$globe_y" );
                        }
                        $extfields->file_type( 'image' );
                        if ( $ext =~ /^jpe?g$/i ) {
                            $image_type = 'JPG';
                        } else {
                            $image_type = uc($ext);
                        }
                        if ( $newthumb ) {
                            $newthumb =~ s/$q_site_path/%r/;
                            $extfields->thumb_metadata( "$thumb_w,$thumb_h" );
                        } else {
                            $newthumb = $thumbnailpath;
                            $thumbnailpath =~ s/%r/$site_path/;
                            if ( -f $thumbnailpath ) {
                                ( $thumb_w, $thumb_h ) = imgsize( $thumbnailpath );
                                $extfields->thumb_metadata( "$thumb_w,$thumb_h" );
                            }
                        }
                        my $newthumb_url = $newthumb;
                        $newthumb_url =~ s/\\/\//g;
                        $extfields->thumbnail( $newthumb_url );
                    } else {
                        if ( $ext =~ /^mov$/i || $ext =~ /^avi$/i || $ext =~ /^3gp$/i ||
                             $ext =~ /^asf$/i || $ext =~ /^mp4$/i || $ext =~ /^qt$/i ||
                             $ext =~ /^wmv$/i || $ext =~ /^asx$/i || $ext =~ /^mpg$/i
                        ) {
                            $extfields->file_type( 'video' );
                            $is_video = 1;
                        } elsif ( $ext =~ /^mp3$/i || $ext =~ /^ogg$/i || $ext =~ /^aiff?$/i ||
                                  $ext =~ /^wav$/i || $ext =~ /^wma$/i || $ext =~ /^aac$/i
                        ) {
                            $extfields->file_type( 'audio' );
                            $is_audio = 1;
                        } else {
                            $extfields->file_type( 'file' );
                        }
                    }
                }
            } else {
                $extfields->text( $text );
            }
            if ( $type eq 'textarea' || $type eq 'file' ) {
                $extfields->transform( $textformat );
            }
            $extfields->label( $label_val );
            $extfields->multiple( $multiple );
            $extfields->select_item( $select_item );
            $extfields->type( $type );
            if ( $type eq 'file_compact' ) {
                $extfields->type( 'file' );
            }
            $extfields->mime_type( $mime_type );
            $extfields->sort_num( $_ );
            $extfields->status( 1 );
            $extfields->save
                or return $app->trans_error( 'Error saving extras: [_1]', $extfields->errstr );
            if ( $type eq 'file' || $type eq 'file_compact' ) {
                if ( $FH && ( $entry_id != -1 ) ) {
                    my $filename = file_basename( $asset_path );
                    my $asset_pkg;
                    if ( $local_basename ) {
                        $asset_pkg = MT->model( 'asset' )->handler_for_file( $local_basename );
                        if ( $is_image ) {
                            $asset_pkg->isa( 'MT::Asset::Image' );
                        } elsif ( $is_video ) {
                            $asset_pkg->isa( 'MT::Asset::Video' );
                        } elsif ( $is_audio ) {
                            $asset_pkg->isa( 'MT::Asset::Audio' );
                        }
                    }
                    my $asset = $asset_pkg->load( { file_path => $asset_path, blog_id => $blog_id } );
                    my $new_asset;
                    unless ( $asset ){
                        $asset = $asset_pkg->new();
                        $new_asset = 1;
                    }
                    unless ( defined $asset ) { # TODO: is not used?
                        $asset = MT->model( 'asset' )->load( { class => '*', url => $asset_path } );
                        if ( defined $asset ) {
                            $new_asset = 0;
                        } else {
                            $asset = MT->model( 'asset' )->new;
                            $new_asset = 1;
                        }
                    }
                    $asset->blog_id( $blog_id );
                    $asset->file_path( $asset_path );
                    my $asset_url = $asset_path;
                    $asset_url =~ s/\\/\//g;
                    $asset->url( $asset_url );
                    $asset->file_name( $filename );
                    $asset->mime_type( $mime_type );
                    $asset->file_ext( $ext );
                    $asset->created_by( $app->user->id );
                    my $asset_type;
                    if ( $is_image ) {
                        $asset_type = 'image';
                    } elsif ( $is_video ) {
                        $asset_type = 'video';
                    } elsif ( $is_audio ) {
                        $asset_type = 'audio';
                    } else {
                        $asset_type = 'file';
                    }
                    $asset->class( $asset_type );
                    $asset->label( $alternative );
                    $asset->description( $description );
                    if ( $is_image ) {
                        $asset->image_width( $globe_x );
                        $asset->image_height( $globe_y );
                    }
                    $asset->save
                            or return $app->trans_error( 'Error saving asset: [_1]', $asset->errstr );
                    my @fdatas = stat( $file );
                    my $bytes = $fdatas[ 7 ];
                    my $full_url = $asset_url;
                    $full_url =~ s/%r/$site_url/;
                    upload_callback( $app, $file, $full_url, $bytes, $asset, $blog, $globe_y, $globe_x, $image_type, $is_image );
                    $asset_id = $asset->id;
                    $extfields->asset_id( $asset_id );
                    $extfields->save
                            or return $app->trans_error( 'Error saving extfields: [_1]', $extfields->errstr );
                    my %param = $app->param_hash;
                    $param{ id } = $asset_id;
                    $asset->on_upload( \%param );
                    if ( $newthumb ) {
                        my $thumb_basename = file_basename( $newthumb );
                        my $thumb_asset_pkg = MT->model( 'asset' )->handler_for_file( $thumb_basename );
                        $thumb_asset_pkg->isa( 'MT::Asset::Image' );
                        my $newthumb_asset = $newthumb;
                        $newthumb_asset =~ s/$q_site_path/%r/;
                        my $thumb_asset = $thumb_asset_pkg->load( { file_path => $newthumb_asset, blog_id => $blog_id } );
                        unless ( $thumb_asset ) {
                            $thumb_asset = $thumb_asset_pkg->new();
                        }
                        unless ( defined $thumb_asset ) {
                            $thumb_asset = MT->model( 'asset' )->load( { class => '*', url => $newthumb } );
                            unless ( defined $thumb_asset ) {
                                $thumb_asset = MT->model( 'asset' )->new;
                            }
                        }
                        $thumb_asset->blog_id( $blog_id );
                        $thumb_asset->file_path( $newthumb_asset );
                        my $newthumb_asset_url = $newthumb_asset;
                        $newthumb_asset_url =~ s/\\/\//g;
                        $thumb_asset->url( $newthumb_asset_url );
                        my $thumbname = file_basename( $newthumb );
                        $thumb_asset->file_name( $thumbname );
                        $thumb_asset->mime_type( $mime_type );
                        $thumb_asset->file_ext( $ext );
                        $thumb_asset->created_by( $app->user->id );
                        $thumb_asset->class( $asset_type );
                        my $thmb_alt;
                        if ( $alternative ) {
                            $thmb_alt = $alternative . $plugin->translate( ' Thumbnail' );
                        } else {
                            $thmb_alt = $thumbname . $plugin->translate( ' Thumbnail' );
                        }
                        $thumb_asset->label( $thmb_alt );
                        $thumb_asset->image_width( $thumb_w );
                        $thumb_asset->image_height( $thumb_h );
                        $thumb_asset->description( $description );
                        $thumb_asset->parent( $asset_id );
                        $thumb_asset->save
                                or return $app->trans_error( 'Error saving asset: [_1]', $asset->errstr );
                        my @fdatas = stat( $newthumb );
                        my $bytes = $fdatas[ 7 ];
                        my $full_url = $newthumb_asset_url;
                        $full_url =~ s/%r/$site_url/;
                        upload_callback( $app, $newthumb, $full_url, $bytes, $thumb_asset, $blog, $thumb_h, $thumb_w, $image_type, $is_image );
                    }
                }
                elsif ( $extfields->id < 0 && $entry_id != -1 ) {
                    my $extfield_original = MT->model( 'extfields' )->load( - ( $extfields->id ) );
                    if ( $extfield_original && $extfield_original->asset_id ) {
                        $extfields->asset_id( $extfield_original->asset_id );
                        $extfields->save;
                    }
                }
            }
        }
    }
}

sub _remove_at_preview {
    my ( $eh, %args ) = @_;
    my $at = $args{ 'ArchiveType' };
    return 1 unless $at eq 'preview';
    my $entry_id = $args{ 'entry_id' };
    my @extras = MT->model( 'extfields' )->load( { entry_id => $entry_id } );
    for my $extfields ( @extras ) {
        my $ext_status = $extfields->status;
        if ( $ext_status == 1 || $entry_id == -1 ) {
            if ( $entry_id == -1 ) {
                $extfields->remove or die 'Error removing extras';
            } else {
                if ( $extfields->type ne 'file' ) {
                    $extfields->remove or die 'Error removing extras';
                } elsif ( $extfields->id < 0 ) {
                    $extfields->remove or die 'Error removing extras';
                } else {
                    $extfields->status( 1 );
                    $extfields->save or die 'Error saving extras';
                }
            }
        } else {
            $extfields->status( 1 );
            $extfields->save or die 'Error saving extras';
            if ( $extfields->id < 0 ) {
                $extfields->remove or die 'Error removing extras';
            }
        }
    }
}

sub _add_ext_buttons {
    my ( $cb, $app, $tmpl ) = @_;
    my $search = quotemeta( '<__trans phrase="Extra Fields">' );
    my $new = $plugin->translate( 'Extra Fields' );
    $$tmpl =~ s/$search/$new/sg; # TODO: is needed? regex num is 0
}

sub _set_localize {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'ExtFields' );
    my $user = current_user( $app );
    my $search = quotemeta( '<h3 class="widget-label"><span>Extra Fields</span></h3>' );
    my $new = '<h3 class="widget-label"><span>' . $plugin->translate( 'Extra Fields' ) . '</span></h3>';
    $$tmpl =~ s/$search/$new/sg;
    $search = quotemeta( '<upload_path>' );
    my $upload_path = $plugin->get_config_value( 'upload_path' );
    if ( $upload_path =~ /%u/ ) {
        my $uname = $user->name;
        $uname =~ s/\s/_/g;
        $upload_path =~ s/%u/$uname/g;
    }
    if ( $upload_path =~ /%i/ ) {
        my $uid = $user->id;
        $upload_path =~ s/%i/$uid/g;
    }
    $upload_path =~ s/(.*)\/$/$1/;
    if ( $upload_path ) {
        $upload_path = "$upload_path/";
    }
    $$tmpl =~ s/$search/$upload_path/sg;
}

sub _set_ext_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'ExtFields' );
    my $user = current_user( $app );
    my $blog = $app->blog;
    my $q = $app->param;
    my $fmgr = $blog->file_mgr;
    my $perms = MT::Permission->load( { blog_id => $blog->id,
                                        author_id => $user->id,
                                      }
                                    );
    my $class = $q->param( '_type' );
    my $can_extfields = ExtFields::Util::can_extfields( $blog, $user, $class );
    my $rem_gif; my $plugin_tmpl;
    if ( $can_extfields ) {
        $plugin_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'extfields.tmpl' );
        $rem_gif = 1;
    } else {
        $plugin_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'extfields_user.tmpl' );
    }
    if ( my $pointer_field = $tmpl->getElementById( 'header_include' ) ) {
        my $nodeset = $tmpl->createElement( 'for',
                                            { id => 'header_include_extfields',
                                              label_class => 'no-label',
                                            }
                                          );
        my $innerHTML = '<mt:include name="' . $plugin_tmpl . '" component="ExtFields">';
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertBefore( $nodeset, $pointer_field );
    }
    my $id = $q->param( 'id' );
    my $html_block = '';
    my $total = 1;
    my $names;
    my $static_uri = $app->static_path;
    if ( my $reedit = $q->param( 'reedit' ) ) {
        $names = $q->param( 'newFldNames' );
        $total = $q->param( 'newFldCount' );
        my @extras = split( /\,/, $names );
        my $count = scalar @extras;
        for ( 1..$count ) {
            my $name = $extras[ $_ - 1 ];
            my $type = $1 if { $name =~ /^.*\-[0-9]{1,}\-(.*$)/ };
            my $text = $q->param( $name );
            my $label = $name . '-label';
            my $label_val = $q->param( $label );
            if ( $label_val ) {
                my $textformat = $q->param( $name . '-textformat' );
                if ( $type eq 'text' ) {
                    $html_block .= &_input_tmpl( $label_val, $name, $text, $static_uri, $rem_gif );
                } elsif ( $type eq 'date' ) {
                    my $time = $q->param( $name . '-time' );
                    $html_block .= &_date_tmpl( $label_val, $name, $text, $static_uri, $rem_gif, $time );
                } elsif ( $type eq 'textarea' ) {
                    $html_block .= &_tarea_tmpl( $label_val, $name, $text, $static_uri, $rem_gif, $textformat );
                } elsif ( $type eq 'radio' ) {
                    my $multiple;
                    $multiple = $q->param( $name . '-multiple' );
                    my @multiples = split( /,/, $multiple );
                    my $src; my $i = 1;
                    $text = encode_html( $text );
                    foreach my $item ( @multiples ) {
                        $item = encode_html( $item );
                        $src .= '<label style="margin-right:15px"><input type="radio" name="' . $name . '" id="' . $name . $i;
                        if ( $text eq $item ) {
                            $src .= '" value="' . $item . '" mt:watch-change="1" style="margin-right:7px" checked="checked" />' . $item . '</label>';
                        } else {
                            $src .= '" value="' . $item . '" mt:watch-change="1" style="margin-right:7px" /> ' . $item . '</label>';
                        }
                        $i++;
                    }
                    $html_block .= &_radio_tmpl( $label_val, $name, $src, $static_uri, $rem_gif, $multiple );
                } elsif ( $type eq 'cbgroup' ) {
                    my $multiple;
                    $multiple = $q->param( $name . '-multiple' );
                    my @multiples = split( /,/, $multiple );
                    my $src; my $i = 1;
                    my @multi_vals = split( /,/, $multiple );
                    my $j = 1;
                    for my $m_val ( @multi_vals ) {
                        my $q_val = $q->param( $name . $j );
                        if ( $q_val ) {
                            $text .= $m_val ? ( ',' . $m_val ) : $m_val;
                        }
                        $j++;
                    }
                    $text = encode_html( $text );
                    my @actives = split( /,/, $text );
                    foreach my $item ( @multiples ) {
                        $item = encode_html( $item );
                        $src .= '<label style="margin-right:15px"><input type="checkbox" name="' . $name . $i . '" id="' . $name . $i;
                        if ( grep( /^$item$/, @actives ) ) {
                            $src .= '" value="' . $item . '" mt:watch-change="1" style="margin-right:7px" checked="checked" />' . $item . '</label>';
                        } else {
                            $src .= '" value="' . $item . '" mt:watch-change="1" style="margin-right:7px" /> ' . $item . '</label>';
                        }
                        $i++;
                    }
                    $html_block .= &_cbgroup_tmpl( $label_val, $name, $src, $static_uri, $rem_gif, $multiple );
                } elsif ( $type eq 'select' ) {
                    my $multiple = $q->param( $name . '-multiple' );
                    my @multiples = split( /,/,$multiple );
                    my $src; my $i = 1;
                    $text = encode_html( $text );
                    foreach my $item ( @multiples ) {
                        $item = encode_html( $item );
                        $src .= '<option id="' . $name . $i;
                        if ( $text eq $item ) {
                            $src .= '" value="' . $item . '" selected="selected">' . $item . '</option>';
                        } else {
                            $src .= '" value="' . $item . '"> ' . $item . '</option>';
                        }
                        $i++;
                    }
                    $html_block .= &_select_tmpl( $label_val, $name, $src, $static_uri, $rem_gif, $multiple );
                } elsif ( $type eq 'checkbox' ) {
                    my $option;
                    my $select_item = $q->param( $name . '-select_item' );
                    if ( $text ) {
                        $option = 'checked="checked"';
                    }
                    $html_block .= &_checkbox_tmpl( $label_val, $name, $text, $static_uri, $rem_gif, $option, $select_item );
                } elsif ( $type eq 'file' || $type eq 'file_compact') {
                    my $full_path = $q->param( $name . '-fullpath' );
                    if ( $q->param( $name . '-fullpath-replace' ) ) {
                        $full_path = $q->param( $name . '-fullpath-replace' );
                    }
                    my $file_path = $q->param( $name . '-filepath' );
                    $file_path = encode_url( $file_path );
                    $file_path =~ s/%2F/\//g;
                    $file_path =~ s/\.\.//g;
                    $full_path =~ s/\.\.//g;
                    if ( is_windows() ) {
                        $file_path =~ s/\//\\/g;
                    }
                    my $alternative = $q->param( $name . '-alttext' );
                    my $description = $q->param( $name . '-desctext' );
                    my $mimetype = $q->param( $name . '-mimetype' );
                    my $thumb_path = $q->param( $name . '-thumbnailpath' );
                    if ( $q->param( $name . '-mimetype-replace' ) ) {
                        $mimetype = $q->param( $name . '-mimetype-replace' );
                        $thumb_path = $q->param( $name . '-thumbnailpath-replace' );
                    }
                    my $multiple = $q->param( $name . '-multiple' );
                    my $delete = $q->param( $name . '-delete' );
                    if ( $delete ) {
                        $delete = 'checked="checked"';
                    }
                    my $site_url = site_url( $blog );
                    $site_url =~ s/(^.*)\/$/$1/;
                    $text = $full_path;
                    $text =~ s/%r/$site_url/;
                    my $site_path = site_path( $blog );
                    my $file = $full_path;
                    $file =~ s/%r/$site_path/;
                    my $height;
                    if ( -f $file ) {
                        my ( $globe_x, $globe_y ) = imgsize( $file );
                        if ( $globe_y ) {
                            if ( $globe_y < 150 ) {
                                $height = $globe_y . 'px';
                            } else {
                                $height = '150px';
                            }
                        }
                    }
                    my $tag;
                    if ( $text =~ /\.jpe?g$/i || $text =~ /\.gif$/i || $text =~ /\.png$/i ) {
                        my $fpath = $text;
                        if ( is_windows() ) {
                            $fpath =~ s/\\/\//g;
                        }
                        if ( $thumb_path ) {
                            my $tmpfpath = $thumb_path;
                            $tmpfpath =~ s/\\/\//g if ( is_windows() );
                            if ( $tmpfpath =~ m#([^/]+)$# ) {
                                my $thumb_file_name = $1;
                                $fpath =~ s{[^/]+$}{$thumb_file_name};
                            }
                        }
                        if ( $fpath && $app->is_secure ) {
                            $fpath =~ s/http\:/https\:/;
                        }
                        $tag = "<p style=\"width:100%; height:$height; margin-bottom:2px; overflow:auto\"><img src=\"$fpath\" alt=\"$name-view\" /></p>";
                    }
                    my $overwrite = $q->param( $name . '-overwrite' );
                    my $rename;
                    if ( $overwrite eq 'rename' ) {
                        $overwrite = '';
                        $rename = 'checked=checked';
                    } else {
                        $rename = '';
                        $overwrite = 'checked=checked';
                    }
                    my $is_compact;
                    if ( $type eq 'file_compact' ) {
                         $is_compact = 1;
                    }

                    if ( $fmgr->exists( $file ) ) {
                        my $asset_id; my $asset_obj;
                        my $match_url = $full_path;
                        if ( is_windows() ) {
                            $match_url =~ s/\\/\//g;
                        }
                        $asset_obj = MT->model( 'asset' )->load( { blog_id => $blog->id,
                                                                   class => '*',
                                                                   url => $match_url,
                                                                 },
                                                               );
                        if ( defined $asset_obj ) {
                            $asset_id = $asset_obj->id;
                            if ( $asset_obj->has_thumbnail ) {
                                my %arg;
                                if ( $is_compact ) {
                                    $arg{ Width } = 64;
                                    $arg{ Height } = 64;
                                } else {
                                    $arg{ Width } = 200;
                                    $arg{ Height } = 200;
                                }
                                my ( $url, $w, $h ) = $asset_obj->thumbnail_url( %arg );
                                my $file = $url;
                                $file =~ s/$site_url/$site_path/;
                                if ( is_windows() ) {
                                    $file =~ s/\\/\//g;
                                }
                                if ( -f $file ) {
                                    my ( $th_x, $th_y ) = imgsize( $file );
                                    if ( $th_y ) {
                                        if ( $th_y < 150 ) {
                                            $height = $th_y . 'px';
                                        }
                                    }
                                    my $secure_url = $url;
                                    if ( $app->is_secure ) {
                                        $secure_url =~ s/http\:/https\:/;
                                    }
                                    $tag = "<p style=\"width:100%; height:$height; margin-bottom:2px; overflow:auto\"><img src=\"$secure_url\" alt=\"$name-view\" /></p>";
                                }
                            }
                        }
                        $html_block .= &_e_file_tmpl( $label_val, $name, $text, $static_uri,
                                                      $rem_gif, $file_path, $full_path, $tag, $alternative, $delete,
                                                      $mimetype, $description, $thumb_path, $app->user, $textformat,
                                                      $asset_id, $overwrite, $rename, $perms, $is_compact );
                    } else {
                        $html_block .= &_file_tmpl( $label_val, $name, $text, $static_uri, $rem_gif, $file_path,
                                                    $alternative, $overwrite, $rename, $description, $app->user, $textformat, $is_compact );
                    }
                }
            }
        }
    } else {
        if ( $id ) {
            my @extras = MT->model( 'extfields' )->load( { entry_id => $id,
                                                           status => 1,
                                                         }, {
                                                           'sort' => 'sort_num',
                                                         }
                                                       );
            if ( @extras ) {
                for my $extra ( @extras ) {
                    my $name = $extra->name;
                    my $label = $extra->label;
                    my $type = $extra->type;
                    my $text = $extra->text;
                    my $multiple = $extra->multiple;
                    my $mime_type = $extra->mime_type;
                    my $fld_name = $name . '-' . $type;
                    my $textformat = $extra->transform;
                    if ( $type eq 'text' ) {
                        $html_block .= &_input_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif );
                    } elsif ( $type eq 'date' ) {
                        my $time = substr( $text, 8, 6 );
                        $time = substr( $time, 0, 2 ) . ':' . substr( $time, 2, 2 ) . ':' . substr( $time, 4, 2 );
                        $text = substr( $text, 0, 8 );
                        $text = substr( $text, 0, 4 ) . '-' . substr( $text, 4, 2 ) . '-' . substr( $text, 6, 2 );
                        $html_block .= &_date_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif, $time );
                    } elsif ( $type eq 'textarea' ) {
                        $html_block .= &_tarea_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif, $textformat );
                    } elsif ( $type eq 'radio' ) {
                        my @multiples = split( /,/, $multiple );
                        my $src; my $i = 1;
                        $text = encode_html( $text );
                        foreach my $item ( @multiples ) {
                            $item = encode_html( $item );
                            $src .= '<label style="margin-right:15px"><input type="radio" name="' . $fld_name . '" id="' . $fld_name . $i;
                            if ( $text eq $item ) {
                                $src .= '" value="' . $item . '" mt:watch-change="1" checked="checked" /> ' . $item . '</label>';
                            } else {
                                $src .= '" value="' . $item . '" mt:watch-change="1" /> ' . $item . '</label>';
                            }
                            $i++;
                        }
                        $html_block .= &_radio_tmpl( $label, $fld_name, $src, $static_uri, $rem_gif, $multiple );
                    } elsif ( $type eq 'cbgroup' ) {
                        my @multiples = split( /,/,$multiple );
                        my $src; my $i = 1;
                        $text = encode_html( $text );
                        my @actives = split( /,/,$text );
                        foreach my $item ( @multiples ) {
                            $item = encode_html( $item );
                            $src .= '<label style="margin-right:15px"><input type="checkbox" name="' . $fld_name . $i . '" id="' . $fld_name . $i;
                            if ( grep( /^$item$/, @actives ) ) {
                                $src .= '" value="' . $item . '" mt:watch-change="1" checked="checked" /> ' . $item . '</label>';
                            } else {
                                $src .= '" value="' . $item . '" mt:watch-change="1" /> ' . $item . '</label>';
                            }
                            $i++;
                        }
                        $html_block .= &_cbgroup_tmpl( $label, $fld_name, $src, $static_uri, $rem_gif, $multiple );
                    } elsif ( $type eq 'select' ) {
                        my @multiples = split( /,/, $multiple );
                        my $src; my $i = 1;
                        $text = encode_html( $text );
                        for my $item ( @multiples ) {
                            $item = encode_html( $item );
                            $src .= '<option id="' . $fld_name . $i;
                            if ( $text eq $item ) {
                                $src .= '" value="' . $item . '" selected="selected"> ' . $item.'</option>';
                            } else {
                                $src .= '" value="' . $item . '"> ' . $item . '</option>';
                            }
                            $i++;
                        }
                        $html_block .= &_select_tmpl( $label, $fld_name, $src, $static_uri, $rem_gif, $multiple );
                    } elsif ( $type eq 'checkbox' ) {
                        my $option;
                        my $select_item = $extra->select_item;
                        if ( $text ) {
                            $option = 'checked="checked"';
                        }
                        $html_block .= &_checkbox_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif, $option, $select_item );
                    } elsif ( $type eq 'file' || $type eq 'file_compact') {
                        my $duplicate = $q->param( 'duplicate' );
                        my $duplicate_item = $plugin->get_config_value( 'duplicate_item' );
                        my $file_path = $extra->file_path;
                        my $full_path = $text;
                        my $alternative = $extra->alternative;
                        my $description = $extra->description;
                        my $thumbnail_path = $extra->thumbnail;
                        my $is_compact = $extra->compact;
                        if ( $is_compact eq 1 ) {
                            $fld_name .= "_compact";
                        }
                        if ( ! $duplicate_item && $duplicate ) {
                            $text = '';
                        }
                        if ( $text ) {
                            my $site_url = site_url( $blog );
                            $site_url =~ s/^(.*)\/$/$1/;
                            $text =~ s/%r/$site_url/;
                            my $file = $full_path;
                            my $site_path = site_path( $blog );
                            $file =~ s/%r/$site_path/;
                            my $height;
                            if ( $fmgr->exists( $file ) ) {
                                my ( $globe_x, $globe_y ) = imgsize( $file );
                                if ( $globe_y ) {
                                    if ( $globe_y < 150 ) {
                                        $height = $globe_y.'px';
                                    } else {
                                        $height = '150px';
                                    }
                                }
                                my $tag;
                                if ( $text =~ /\.jpe?g$/i || $text =~ /\.gif$/i || $text =~ /\.png$/i ) {
                                    my $fpath = $text;
                                    if ( is_windows() ) {
                                        $fpath =~ s/\\/\//g;
                                    }
                                    if ( $fpath && $app->is_secure ) {
                                        $fpath =~ s/http\:/https\:/;
                                    }
                                    $tag = "<p style=\"width:100%; height:$height; margin-bottom:2px; overflow:auto\"><img src=\"$fpath\" alt=\"$name-view\" /></p>";
                                }
                                my $asset_id;
                                my $match_url = $full_path;
                                if ( is_windows() ) {
                                    $match_url =~ s/\\/\//g;
                                }
                                my $asset_obj = MT->model( 'asset' )->load( { blog_id => $blog->id,
                                                                              class => '*',
                                                                              url => $match_url,
                                                                            }
                                                                          );
                                if ( defined $asset_obj ) {
                                    $asset_id = $asset_obj->id;
                                    if ( $asset_obj->has_thumbnail ) {
                                        my %arg;
                                        if ( $is_compact ) {
                                            $arg{ Width } = 64;
                                            $arg{ Height } = 64;
                                        } else {
                                            $arg{ Width } = 200;
                                            $arg{ Height } = 200;
                                        }
                                        my ( $url, $w, $h ) = $asset_obj->thumbnail_url( %arg );
                                        my $file = $url;
                                        $file =~ s/$site_url/$site_path/;
                                        if ( is_windows() ) {
                                            $file =~ s/\\/\//g;
                                        }
                                        if ( $fmgr->exists( $file ) ) {
                                            my ( $th_x, $th_y ) = imgsize( $file );
                                            if ( $th_y ) {
                                                if ( $th_y < 150 ) {
                                                    $height = $th_y . 'px';
                                                }
                                            }
                                            my $secure_url = $url;
                                            if ( $app->is_secure ) {
                                                $secure_url =~ s/http\:/https\:/;
                                            }
                                            $tag = "<p style=\"width:100%; height:$height; margin-bottom:2px; overflow:auto\"><img src=\"$secure_url\" alt=\"$name-view\" /></p>";
                                        }
                                    }
                                }
                                $html_block .= &_e_file_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif, $file_path, $full_path, $tag,
                                                              $alternative, '', $mime_type, $description, $thumbnail_path, $app->user, $textformat,
                                                              $asset_id, '', 'checked="checked"', $perms, $is_compact );
                            } else {
                                $html_block .= &_file_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif, $file_path, $alternative, '',
                                                            'checked="checked"', $description, $app->user, $textformat, $is_compact );
                            }
                        } else {
                            $html_block .= &_file_tmpl( $label, $fld_name, $text, $static_uri, $rem_gif, $file_path, $alternative, '', 'checked="checked"',
                                                        $description, $app->user, $textformat, $is_compact );
                        }
                    }
                    my $max;
                    if ( $name =~ /^extfields\-([0-9]{1,})$/ ) {
                        $max = $1;
                    }
                    if ( $total < $max ) {
                        $total = $max;
                    }
                    if ( $names ) {
                        $names .= ',';
                    }
                    $names .= $fld_name;
                }
                $total++;
            }
        }
    }
    unless ( $id ) {
        $html_block .= '<input type="hidden" name="newentry" id="newentry" value="1" />';
    }
    $total = 0 if ! $total;
    $names = '' if ! $names;
    $html_block = <<__EOT__;
                <div id="ext-flelds-area" class="sortables">
                $html_block
                </div>
                <input type="hidden" id="newFldCount" name="newFldCount" value="$total" />
                <input type="hidden" id="newFldNames" name="newFldNames" value="$names" />
__EOT__
    $perms = $app->permissions;
    my $prefs_type = $class . '_prefs';
    my $pref_param = $app->load_entry_prefs( { type => $class,
                                               prefs => $perms->$prefs_type,
                                             }
                                           );
    my $show_field = $pref_param ? $pref_param->{ 'disp_prefs_show_ext-field' } : 0;
    push( @{ $param->{ 'field_loop'} }, { 'field_id' => 'ext-field',
                                          'lock_field' => '0',
                                          'field_name' => 'ext-field',
                                          'show_field' => $show_field,
                                          'field_label' => $plugin->translate( 'Extra Fields' ),
                                          'label_class' => 'top-label',
#                                          'required' => '1',
                                          'field_html' => $html_block,
                                        }
        );
    push( @{ $param->{ 'disp_prefs_default_fields' } }, { 'name' => 'ext-fields' } );
    my $upload_path = $plugin->get_config_value( 'upload_path' );
    if ( $upload_path =~ /%u/ ) {
        my $uname = $user->name;
        $uname =~ s/\s/_/g;
        $upload_path =~ s/%u/$uname/g;
    }
    if ( $upload_path =~ /%i/ ) {
        my $uid = $user->id;
        $upload_path =~ s/%i/$uid/g;
    }
    if ( $upload_path =~ /(.*)\/$/ ) {
        $upload_path = $1;
    }
    my $tmpl_lang = $app->blog->language;
    $param->{ 'lang'} = $tmpl_lang;
    my $static_path = $app->static_path;
    my $editor_style_css = $plugin->get_config_value( 'ex_editor_style_css' );
    $editor_style_css =~ s/<\${0,1}mt:var\sname="static_uri"\${0,1}>/$static_path/;
    $param->{ 'ex_editor_style_css'}         = $editor_style_css; # TODO: go to tmpl
    $param->{ 'ex_theme_advanced_buttons1' } = $plugin->get_config_value( 'ex_theme_advanced_buttons1' );
    $param->{ 'ex_theme_advanced_buttons2' } = $plugin->get_config_value( 'ex_theme_advanced_buttons2' );
    $param->{ 'ex_theme_advanced_buttons3' } = $plugin->get_config_value( 'ex_theme_advanced_buttons3' );
    $param->{ 'ex_theme_advanced_buttons4' } = $plugin->get_config_value( 'ex_theme_advanced_buttons4' );
    $param->{ 'ex_theme_advanced_buttons5' } = $plugin->get_config_value( 'ex_theme_advanced_buttons5' );
    $param->{ 'hide_extfields' }             = $plugin->get_config_value( 'hide_extfields' );
    $param->{ 'prompt_msg' }                 = $plugin->translate( 'Please enter items Separated by \',\'' );
    $param->{ 'remove_msg' }                 = $plugin->translate( 'Remove this field?' );
    $param->{ 'name_alert_msg' }             = $plugin->translate( 'Please enter new field label.' );
    $param->{ 'cb_msg' }                     = $plugin->translate( 'Please enter value' );
    $param->{ 'exists_msg' }                 = $plugin->translate( 'When file already exists, what would you do?' );
    $param->{ 'overwrite' }                  = $plugin->translate( 'Overwrite' );
    $param->{ 'rename' }                     = $plugin->translate( 'Rename' );
    $param->{ 'destination' }                = $plugin->translate( 'Upload Destination' );
    $param->{ 'siteroot' }                   = $plugin->translate( 'Site Root' );
    $param->{ 'upload_path' }                = $upload_path;
    $param->{ 'itemname' }                   = $plugin->translate( 'Name' );
    $param->{ 'itemdesc' }                   = $plugin->translate( 'Description' );
    $param->{ 'choosefile' }                 = $plugin->translate( 'File' );
    $param->{ 'fpathlabel' }                 = $plugin->translate( 'File Path' );
    $param->{ 'delete' }                     = $plugin->translate( 'Delete' );
    $param->{ 'replace' }                    = $plugin->translate( 'Replace' );
    $param->{ 'format_label3' }              = $plugin->translate( 'Table(Heading=None)' );
    $param->{ 'format_label4' }              = $plugin->translate( 'Table(Heading=Row)' );
    $param->{ 'format_label5' }              = $plugin->translate( 'Table(Heading=Col)' );
    $param->{ 'format_label6' }              = $plugin->translate( 'Table(Heading=Row,Col)' );
    $param->{ 'format_label7' }              = $plugin->translate( 'Unordered List' );
    $param->{ 'format_label8' }              = $plugin->translate( 'Ordered List' );
    $param->{ 'label_text' }                 = $plugin->translate( 'Single-Line Text' );
    $param->{ 'label_textarea' }             = $plugin->translate( 'Multi-Line Textfield' );
    $param->{ 'label_radio' }                = $plugin->translate( 'Radio Buttons' );
    $param->{ 'label_checkbox' }             = $plugin->translate( 'Checkbox' );
    $param->{ 'label_checkbox_group' }       = $plugin->translate( 'Checkbox Group' );
    $param->{ 'label_select' }               = $plugin->translate( 'Drop Down Menu' );
    $param->{ 'label_file' }                 = $plugin->translate( 'File Attachment' );
    $param->{ 'label_file_compact' }         = $plugin->translate( 'File Attachment Compact' );
    $param->{ 'label_date' }                 = $plugin->translate( 'Date and Time' );
    $param->{ 'lang_ym' }                    = $plugin->translate( 'lang_ym_0' );
    $param->{ 'atattch_y' }                  = $plugin->translate( '<!--atattch_y-->' );
    $param->{ 'use_multipart' }              = 1;

    if ( my $pointer_field = $tmpl->getElementById( 'field_end' ) ) {
        my $nodeset = $tmpl->createElement( 'for',
                                            { id => 'extfields_tyle',
                                              label_class => 'no-label',
                                            }
                                          );
        my $innerHTML = <<'HTML';
<mt:ignore>
<mt:if name="hide_extfields">
<h3 id="extfields-block-label"
    style="color:gray;font-size:1em;
    margin-top:-7px;
    margin-bottom:8px;
    background-repeat:no-repeat;
    background-position:left;
    padding-left:10px;
    background-image:url(<mt:var name="static_uri">images/spinner-right.gif)"
    ><a href="javascript:void(0)" onclick="toggle_extfields()"><__trans phrase="Extra Fields"></a></h3>
</mt:if>
<fieldset id="entry-extfields-settings">
    <div id="ext-flelds-area">
    <!--[[ext_fields]]-->
    </div>
    <input type="hidden" id="newFldCount" name="newFldCount" value="<!--[[ext_fields_count]]-->" />
    <input type="hidden" id="newFldNames" name="newFldNames" value="<!--[[ext_fields_names]]-->" />

    <script type="text/javascript">
        getByID( 'newFldNames' ).value = '<!--[[ext_fields_names]]-->';
        getByID( 'newFldCount' ).value = '<!--[[ext_fields_count]]-->';
    </script>
</fieldset>
<mt:if name="hide_extfields">
    <script type="text/javascript">
    getByID( 'entry-extfields-settings' ).style.display = 'none';
    function toggle_extfields( ) {
        if ( getByID( 'entry-extfields-settings' ).style.display == 'none' ) {
            getByID( 'entry-extfields-settings' ).style.display = 'block';
            getByID( 'extfields-block-label' ).style.backgroundImage = 'url(<mt:var name="static_uri">images/spinner-bottom.gif)';
        } else {
            getByID( 'entry-extfields-settings' ).style.display = 'none';
            getByID( 'extfields-block-label' ).style.backgroundImage = 'url(<mt:var name="static_uri">images/spinner-right.gif)';
        }
    }
    </script>
</mt:if>
</mt:ignore>
HTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertBefore( $nodeset, $pointer_field );
    }
    if ( $app->param( 'duplicate' ) ) {
        if ( my $pointer_field = $tmpl->getElementById( 'hidden_etc' ) ) {
            my $nodeset = $tmpl->createElement( 'for',
                                                { id => 'hidden_etc_duplicate',
                                                  label_class => 'no-label',
                                                }
                                              );
            my $innerHTML = '<input type="hidden" name="duplicate" value="1" />';
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer_field );
        }
    }
    if ( my $pointer_field = $tmpl->getElementById( 'metadata_fields_etc' ) ) {
        my $nodeset = $tmpl->createElement( 'for',
                                            { id => 'metadata_fields_etc_extfields',
                                              label_class => 'no-label',
                                            }
                                          );
        my $innerHTML =<<"MTML";
<__trans_section component="ExtFields">
    <li><label><input type="checkbox" name="custom_prefs" id="custom-prefs-ext-fields" value="ext-fields" onclick="setCustomFields(); return true"<mt:if name="disp_prefs_show_ext-fields"> checked="checked"</mt:if> class="cb" /> <__trans phrase="Extra Fields"></label></li>
</__trans_section>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer_field );
    }
    if ( $id ) {
        my $count = MT->model( 'extfields' )->load( { entry_id => $id } );
        if ( $count ) {
            return $param->{ 'if_ext_fields' } = 1;
        } else {
            return $param->{ 'if_ext_fields' } = 0;
        }
    }
1;
}

sub _input_tmpl {
    my ( $label, $name, $text, $static_uri, $rem_gif ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $text = ExtFields::Util::amp_escape( $text );
    $text = encode_html( $text );
    $label = encode_html( $label );
    my $hidden_label = $name . '-label';
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
            <input type="text" name="$name" id="$name" class="text full" value="$text" mt:watch-change="1" autocomplete="off" />
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
        </div>
    </div>
    </div>
HTML
}

sub _date_tmpl {
    my ( $label, $name, $text, $static_uri, $rem_gif, $time ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $text = encode_html( $text );
    $label = encode_html( $label );
    my $hidden_label = $name . '-label';
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
            <span class="date-time-field">
            <input type="text" name="$name" id="$name" value="$text" mt:watch-change="1" autocomplete="off" class="entry-date text-date" />
            <input type="text" name="$name-time" id="$name-time" value="$time" mt:watch-change="1" autocomplete="off" class="entry-time" />
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
        </div>
    </div>
    </div>
HTML
}

sub _tarea_tmpl {
    my ( $label, $name, $text, $static_uri, $rem_gif, $textformat ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $text = ExtFields::Util::amp_escape( $text );
    $text = encode_html( $text );
    $label = encode_html( $label );
    my $hidden_label = $name . '-label';
    my $num = $1 if { $name =~ /^.*\-([0-9]{1,}?)\-/ };
    my $format_selector = _make_text_format( $name, $textformat, 'textarea' );
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
            $format_selector
            <textarea style="height:90px" name="$name" id="$name" class="text full low ta" rows="" mt:watch-change="1">$text</textarea>
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
        </div>
    </div>
    </div>
HTML
}

sub _radio_tmpl {
    my ( $label, $name, $src, $static_uri, $rem_gif, $multiple_items ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $multiple_items = encode_html( $multiple_items );
    $label = encode_html( $label );
    my $hidden_label = $name . '-label';
    my $multiples_fld_val = $name . '-multiple';
    my $num = $1 if { $name =~ /^.*\-([0-9]{1,}?)\-/ };
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content field-content-text">
        <div class="ext-field-content-inner">
            <div>$src</div>
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
            <input name="$multiples_fld_val" id="$multiples_fld_val" value="$multiple_items" type="hidden" />
        </div>
    </div>
    </div>
HTML
}

sub _cbgroup_tmpl {
    my ( $label, $name, $src, $static_uri, $rem_gif, $multiple_items ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $multiple_items = encode_html( $multiple_items );
    $label = encode_html( $label );
    my $hidden_label = $name . '-label';
    my $multiples_fld_val = $name . '-multiple';
    my $num = $1 if { $name =~ /^.*\-([0-9]{1,}?)\-/ };
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content field-content-text">
        <div class="ext-field-content-inner">
            <div>$src</div>
            <input name="$name" id="$name" value="1" type="hidden" />
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
            <input name="$multiples_fld_val" id="$multiples_fld_val" value="$multiple_items" type="hidden" />
        </div>
    </div>
    </div>
HTML
}

sub _select_tmpl {
    my ( $label, $name, $src, $static_uri, $rem_gif, $multiple_items ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $label = encode_html( $label );
    $multiple_items = encode_html( $multiple_items );
    my $hidden_label = $name . '-label';
    my $multiples_fld_val = $name . '-multiple';
    my $num = $1 if { $name =~ /^.*\-([0-9]{1,}?)\-/ };
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
            <div><select name="$name" id="$name" class="full-width short" mt:watch-change="1">$src</select></div>
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
            <input name="$multiples_fld_val" id="$multiples_fld_val" value="$multiple_items" type="hidden" />
        </div>
    </div>
    </div>
HTML
}

sub _checkbox_tmpl {
    my ( $label, $name, $text, $static_uri, $rem_gif, $option, $select_item ) = @_;
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $text = encode_html( $text );
    $label = encode_html( $label );
    $select_item = encode_html( $select_item );
    my $hidden_label = $name . '-label';
    my $hidden_select_item = $name . '-select_item';
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content field-content-text">
        <div class="ext-field-content-inner">
            <div>
            <label>
                <input type="checkbox" name="$name" id="$name" value="1" mt:watch-change="1" autocomplete="off"
                    style="margin-right:7px" $option />$select_item</label>
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
            <input name="$hidden_select_item" id="$hidden_select_item" value="$select_item" type="hidden" />
            </div>
        </div>
    </div>
    </div>
HTML
}

sub _file_tmpl {
    my ( $label, $name, $text, $static_uri, $rem_gif, $file_path, $alt_text, $overwrite, $rename, $desc_text, $user, $textformat, $is_compact ) = @_;
    my $plugin = MT->component( 'ExtFields' );
    my $format_selector = _make_text_format( $name, $textformat, 'file' );
    my $upload_path = $plugin->get_config_value( 'upload_path' );
    if ( $upload_path =~ /%u/ ) {
        my $uname = $user->name;
        $uname =~ s/\s/_/g;
        $upload_path =~ s/%u/$uname/g;
    }
    if ( $upload_path =~ /%i/ ) {
        my $uid = $user->id;
        $upload_path =~ s/%i/$uid/g;
    }
    if ( $upload_path =~ /(.*)\/$/ ) {
        $upload_path = $1;
    }
    if ( $upload_path ) {
        $upload_path = "$upload_path/";
    }
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $text = encode_html( $text );
    $label = encode_html( $label );
    $alt_text = ExtFields::Util::amp_escape( $alt_text );
    $alt_text = encode_html( $alt_text );
    $desc_text = ExtFields::Util::amp_escape( $desc_text );
    $desc_text = encode_html( $desc_text );
    my $hidden_label = $name . '-label';
    if ( $is_compact eq 1 ) {
        return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
        <div class="ext-field-content-border">
            <div class="ext-field-file-alt" style="margin-bottom:8px">
                <label><mt:var name="itemname">: </label>
                <input class="text full border"
                 type="text" name="$name-alttext" id="$name-alttext" value="$alt_text"
                 mt:watch-change="1" autocomplete="off" style="margin-top: 5px" />
            </div>
            <div class="ext-field-file-file" style="margin-bottom: 8px;">
                <label><mt:var name="choosefile">:
                <input type="file" name="$name" id="$name" mt:watch-change="1" autocomplete="off" style="font-size:11px;vertical-align:middle;" /></label>
            </div>

            <div>
                <input type="hidden" name="$name-textformat" value="1" />
                <input type="hidden" name="$name-desctext" value="" />
                <input type="hidden" name="$name-overwrite" value="rename" />
                <input type="hidden" name="$name-filepath" value="" />
            </div>
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
        </div>
        </div>
    </div>
    </div>
HTML
    } else {
        return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
        <div class="ext-field-content-border">
            <div class="ext-field-file-alt" style="margin-bottom:8px">
                <label><mt:var name="itemname">: </label>
                <input class="text full border"
                 type="text" name="$name-alttext" id="$name-alttext" value="$alt_text"
                 mt:watch-change="1" autocomplete="off" style="margin-top: 5px" />
            </div>

            <div class="ext-filed-file-description extfield-extend-field" style="display:block;margin-bottom:8px">
                <label><mt:var name="itemdesc">: </label>
                $format_selector
                <textarea name="$name-desctext" id="$name-desctext"
                 class="text full low" style="margin-top: 5px">$desc_text</textarea>
            </div>

            <div class="ext-field-file-file" style="margin-bottom: 8px;">
                <label><mt:var name="choosefile">:
                <input type="file" name="$name" id="$name" mt:watch-change="1" autocomplete="off" style="font-size:11px;vertical-align:middle;" /></label>
            </div>

            <div class="ext-field-file-path extfield-extend-field" style="margin-bottom: 8px;">
                <label><mt:var name="destination">: &#60;<mt:var name="siteroot">&#62; /$upload_path
                <input type="text" name="$name-filepath" id="$name-filepath" value="$file_path"
                 mt:watch-change="1" autocomplete="off" class="border" style="width:120px;" /></label>
            </div>
            <div class="ext-field-file-overwrite extfield-extend-field">
                <mt:var name="exists_msg">
                <label>
                    <input type="radio" name="$name-overwrite" id="$name-overwrite1" value="overwrite"
                     style="margin-right:5px; margin-left:12px" mt:watch-change="1" autocomplete="off" $overwrite />
                    <mt:var name="overwrite">
                </label>
                <label>
                    <input type="radio" name="$name-overwrite" id="$name-overwrite2" value="rename"
                     style="margin-right:5px; margin-left:9px" mt:watch-change="1" autocomplete="off" $rename />
                     <mt:var name="rename">
                </label>
            </div>
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
        </div>
        </div>
    </div>
    </div>
HTML
    }
}

sub _e_file_tmpl {
    my ( $label, $name, $text, $static_uri, $rem_gif, $file_path, $full_path, $tag,
        $alt_text, $delete, $mime_type, $desc_text, $thumb_path, $user, $textformat,
        $asset_id, $overwrite, $rename, $perms, $is_compact ) = @_;
    my $cms_user = current_user();
    my $edit_tag;
    if ( $asset_id ) {
        my $can_extfields;
        if ( $cms_user->is_superuser ) {
            $can_extfields = 1;
        }
        if ( $perms && $perms->can_edit_assets ) {
            $can_extfields = 1;
        }
        if ( $can_extfields ) {
            $edit_tag = '<a title="<mt:var name="phrase_edit">" href="<$MTAdminScript$>?__mode=view&_type=asset&dialog_view=1&__type=dialog';
            $edit_tag.= '&id=' . $asset_id . '&blog_id=<mt:var name="blog_id">" class="mt-open-dialog">';
            $edit_tag.= '<img src="<mt:var name="static_uri">images/nav_icons/color/new-entry.gif" alt="<mt:var name="phrase_edit">" width="17" height="15" style="vertical-align:middle" /></a>';
        }
    }
    my $format_selector = _make_text_format( $name, $textformat, 'file' );
    my $wrapper = $name . '-wrap';
    my $gif;
    my $sort;
    if ( $rem_gif ) {
        $gif = _make_buttons( $name, $static_uri );
        $sort = _make_sortimage( $name, $static_uri );
    }
    $text = encode_html( $text );
    $label = encode_html( $label );
    $file_path = encode_html( $file_path );
    $alt_text = ExtFields::Util::amp_escape( $alt_text );
    $alt_text = encode_html( $alt_text );
    $desc_text = ExtFields::Util::amp_escape( $desc_text );
    $desc_text = encode_html( $desc_text );
    $text =~ s/\\/\//g;
    $file_path =~ s/\\/\//g;
    my $hidden_label = $name . '-label';
    my $textarea;
    if ( $is_compact eq 1 ) {
        $textarea = '<input type="hidden" name="' . $name . '-desctext" value="' . $desc_text . '" />';
        $textarea.= '<input type="hidden" name="' . $name . '-compact" value="1" />';
    } else {
        $textarea  = '<div class="ext-filed-file-description extfield-extend-field" style="display:block;margin-bottom:8px">';
        $textarea .= '<label><mt:var name="itemdesc">: </label>';
        $textarea .= $format_selector;
        $textarea .= '<textarea name="' . $name . '-desctext" id="' . $name . '-desctext" class="text full short" style="margin-top: 5px">';
        $textarea .= $desc_text;
        $textarea .= '</textarea></div>';
    }
    return <<"HTML";
    <div id="$wrapper" class="field field-top-label ext-field">
    <div class="ext-field-header">
        <label>$sort $label<mt:if name="config.DebugMode" ge="1">($name)</mt:if> $gif</label>
    </div>
    <div class="ext-field-content">
        <div class="ext-field-content-inner">
        <div class="ext-field-content-border">
            <div class="ext-field-thumbnail" style="margin-bottom: 8px;">
                <mt:var name="fpathlabel">: <a href="$text" target="_blank">$text</a> $edit_tag<br />
                $tag
            </div>
            <div class="ext-field-file-alt" style="margin-bottom:8px">
                <label><mt:var name="itemname">: </label>
                <input class="text full short border"
                 type="text" name="$name-alttext" id="$name-alttext" value="$alt_text"
                 mt:watch-change="1" autocomplete="off" style="margin-top: 5px" />
            </div>

            $textarea

            <div style="margin-left:2px;margin-top:5px;margin-bottom:1px;display:block">
                <label>
                    <input type="checkbox" onclick="remove_extfile(this,'$name','$name-overwrite1','$name-overwrite2','$name-replace' )"
                     name="$name-delete" id="$name-delete" value="1" $delete /> <mt:var name="delete">
                </label>
                &nbsp;&nbsp;
                <label>
                    <input type="checkbox" onclick="overwrite_extfile(this,'$name','$name-overwrite1','$name-overwrite2','$name-delete' )"
                     name="$name-replace" id="$name-replace" value="1" /> <mt:var name="replace">
                </label>
                &nbsp;&nbsp;
                <label>
                    <mt:var name="choosefile">:
                    <input type="file" name="$name" id="$name" mt:watch-change="1" autocomplete="off" disabled="disabled" style="font-size:11px;vertical-align:middle;" />
                </label>
                <label>
                    <input type="radio" disabled="disabled" name="$name-overwrite" id="$name-overwrite1" value="overwrite"
                     style="margin-right:5px; margin-left:12px;vertical-align:middle;" mt:watch-change="1" autocomplete="off" $overwrite
                /><mt:var name="overwrite"></label><label><input type="radio" disabled="disabled" name="$name-overwrite" id="$name-overwrite2" value="rename"
                style="margin-right:5px; margin-left:9px;vertical-align:middle;" mt:watch-change="1" autocomplete="off" $rename /><mt:var name="rename"></label>
            </div>
            <input type="hidden" name="$name-filepath" id="$name-filepath" value="$file_path" />
            <input type="hidden" name="$name-fullpath" id="$name-fullpath" value="$full_path" />
            <input type="hidden" name="$name-mimetype" id="$name-mimetype" value="$mime_type" />
            <input type="hidden" name="$name-thumbnailpath" id="$name-thumbnailpath" value="$thumb_path" />
            <input name="$hidden_label" id="$hidden_label" value="$label" type="hidden" />
        </div>
        </div>
    </div>
    </div>
HTML
}

sub _make_buttons {
    my ( $name, $static_uri ) = @_;
    my $gif;
    $gif .= '<span class="ext-field-buttons">';
    $gif .= ' <a href="javascript:void(0);" rel="' . $name . '-wrap"><img src="' . $static_uri;
    $gif .= 'images/status_icons/close.gif" width="9" height="9" class="remove icon" style="vertical-align:1px;" /></a>';
    $gif .= '</span>';
    return $gif;
}

sub _make_sortimage {
    my ( $name, $static_uri ) = @_;
    my $sort;
    $sort .= '<span class="sort-handle">';
    $sort .= '<img src="' . $static_uri . 'plugins/ExtFields/images/dragdrop_min.gif" width="13" height="11" alt="" style="margin-right:5px;vertical-align:0;" />';
    $sort .= '</span>';
    return $sort;
}

sub _make_text_format {
    my ( $name, $textformat, $type ) = @_;
    my $selected = 'selected="selected"';
    my $sel1  = '';
    my $sel2  = '';
    my $sel3  = '';
    my $sel4  = '';
    my $sel5  = '';
    my $sel6  = '';
    my $sel7  = '';
    my $sel8  = '';
    my $sel9  = '';
    my $sel11 = '';
    my $sel12 = '';
    my $sel13 = '';
    my $tiny = 'false';
    if ( $textformat == 1 ) {
        $sel1 = $selected;
    } elsif ( $textformat == 2 ) {
        $sel2 = $selected;
    } elsif ( $textformat == 3 ) {
        $sel3 = $selected;
    } elsif ( $textformat == 4 ) {
        $sel4 = $selected;
    } elsif ( $textformat == 5 ) {
        $sel5 = $selected;
    } elsif ( $textformat == 6 ) {
        $sel6 = $selected;
    } elsif ( $textformat == 7 ) {
        $sel7 = $selected;
    } elsif ( $textformat == 8 ) {
        $sel8 = $selected;
    } elsif ( $textformat == 9 ) {
        $sel9 = $selected;
        $tiny = 'true';
    } elsif ( $textformat == 11 ) {
        $sel11 = $selected;
    } elsif ( $textformat == 12 ) {
        $sel12 = $selected;
    } elsif ( $textformat == 13 ) {
        $sel13 = $selected;
    }
    my $target;
    if ( $type eq 'textarea' ) {
        $target = '';
    } elsif ( $type eq 'file' ) {
        $target = '-desctext';
    }
    return 0 if ! is_application();
    return <<"HTML";
<MTIfIE>
<mt:if name="ie_version" eq="6">
<mt:setvar name="old_internet_explorer" value="0">
</mt:if>
</MTIfIE>
<mt:if name="old_internet_explorer">
<input type="hidden" name="$name-textformat" value="$textformat" />
<mt:else>
<div class="ext-field-format full-width">
<__trans phrase="Format:"> <select name="$name-textformat" id="$name-textformat" rel="$name$target" class="ext-field-formatselect">
    <option value="1" $sel1><__trans phrase="None"></option>
    <option value="2" $sel2><__trans phrase="Convert Line Breaks"></option>
    <option value="11" $sel11>Markdown</option>
    <option value="12" $sel12>Markdown + SmartyPants</option>
    <mt:ifPlugin component="TinyMCE">
    <option value="9" $sel9><__trans phrase="Rich Text"></option>
    </mt:ifPlugin>
    <option value="13" $sel13>Textile 2</option>
    </mt:unless>
</select>
</div>
</mt:if>
HTML
}

sub upload_callback {
    my ( $app, $file, $url, $bytes, $asset,
         $blog, $h, $w, $type, $is_image ) = @_;
    if ( $is_image ) {
        $app->run_callbacks(
            'cms_upload_file.' . $asset->class,
            File  => $file,
            file  => $file,
            Url   => $url,
            url   => $url,
            Size  => $bytes,
            size  => $bytes,
            Asset => $asset,
            asset => $asset,
            Type  => 'image',
            type  => 'image',
            Blog  => $blog,
            blog  => $blog
        );
        $app->run_callbacks(
            'cms_upload_image',
            File       => $file,
            file       => $file,
            Url        => $url,
            url        => $url,
            Size       => $bytes,
            size       => $bytes,
            Asset      => $asset,
            asset      => $asset,
            Height     => $h,
            height     => $h,
            Width      => $w,
            width      => $w,
            Type       => 'image',
            type       => 'image',
            ImageType  => $type,
            image_type => $type,
            Blog       => $blog,
            blog       => $blog
        );
    } else {
        $app->run_callbacks(
            'cms_upload_file.' . $asset->class,
            File  => $file,
            file  => $file,
            Url   => $url,
            url   => $url,
            Size  => $bytes,
            size  => $bytes,
            Asset => $asset,
            asset => $asset,
            Type  => 'file',
            type  => 'file',
            Blog  => $blog,
            blog  => $blog
        );
    }
    return 1;
}

1;

__END__

=head1 NAME

MT::Plugin::ExtFields - 拡張フィールド機能プラグイン

=head1 TAGS

=head2 BLOCKTAGS

=head3 MTExtFields

エントリのコンテキストで使用します。

そのエントリに紐付く拡張フィールドを順に取り出し、
拡張フィールドコンテキストを作ります。

=head4 attributes

=over 4

=item * exclude_label (optional)

除外したいラベルをカンマ区切りで指定します。

=item * sort_order (optional; default "ascend")

取り出す順序を作成順の昇順・降順を指定します。

=back

=head3 MTExtFieldAsset

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当フィールドに紐付くアセット用にアセットコンテキストを作ります。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルに紐付いたアセットの
コンテキストを作りたいときに使用します。

=back

=head3 MTExtFieldsMultiValues

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

チェックボックスグループ、ラジオボタン、ドロップダウンメニューのような複数の選択肢を
もつラベルに関して、拡張フィールド選択肢コンテキストを作ります。

MTExtFieldValue,MTIfExtFieldSelectedタグが拡張フィールド選択肢コンテキストを扱います。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルに紐付いた選択肢の
拡張フィールド選択肢コンテキストを作りたいときに使用します。

=back

=head3 MTIfExtField?

エントリコンテキストで使用します。

そのエントリに拡張フィールドが存在するかどうかをチェックするコンディショナルタグです。

拡張フィールドが存在する場合に真になります。

=head4 attributes

=over 4

=item * label (optional)

指定するとそのラベルの拡張フィールドが存在するかどうかをチェックします。

=back

=head3 MTIfExtFieldSelected?

拡張フィールド選択肢コンテキスト中で使用するコンディショナルタグです。

その選択肢が選択されている場合に真になります。

=head3 MTIfExtFieldType?

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドのタイプをチェックするコンディショナルタグです。

拡張フィールドが指定のタイプの場合に真になります。

=head4 attributes

=over 4

=item * type (required)

チェックするタイプを指定します。

指定可能なタイプは

=over 4

=item * text - テキスト

=item * textarea - テキスト(複数行)

=item * radio - ラジオボタン

=item * checkbox - チェックボックス

=item * cbgroup - チェックボックスグループ

=item * select - ドロップダウン

=item * file - ファイル添付/ファイル添付(コンパクト)

=item * date - 日付と時刻

=back

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルのタイプをチェックしたいときに使用します。

=back

=head3 MTIfExtFieldTypeImage?

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルかどうかをチェックするコンディショナルタグです。

拡張フィールドタイプがfileでその中でも画像扱いのときに真になります。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルのチェックをしたいときに使用します。

=back

=head3 MTIfExtFieldFileExists?

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドのファイルが存在するかどうかをチェックするコンディショナルタグです。

拡張フィールドタイプがfileでサーバ上にファイルが存在する場合に真になります。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルのファイル存在チェックをしたいときに使用します。

=back

=head3 MTIfExtFieldThumbnailExists?

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドのサムネイルが存在するかどうかをチェックするコンディショナルタグです。

拡張フィールドタイプがfileでその中でも画像扱いのとき、
サーバ上にサムネイルファイルが存在する場合に真になります。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルのサムネイル存在チェックをしたいときに使用します。

=back

=head3 MTIfExtFieldNonEmpty?

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドのテキストの中身をチェックするコンディショナルタグです。

拡張フィールドのテキスト属性の中身が空でない場合に真になります。
(中身が'0'の場合は偽になります。)

テキスト属性に何が入るかは、拡張フィールドタイプ毎に異なります。
MTExtFieldTextを参照してください。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で指定ラベルのテキストチェックをしたいときに使用します。

=back

=head3 MTIfExtFieldCompare?

拡張フィールドのコンテキストで使用します。

該当拡張フィールドのラベルとテキストをチェックするコンディショナルタグです。

以下の条件で真になります。

    | label属性 | text属性 | 真になる条件
    |    有     |   有     | 現在の拡張フィールドが指定のラベルでテキスト内容が一致する。
    |    有     |   無     | 現在の拡張フィールドが指定のラベルである。
    |    無     |   有     | 現在の拡張フィールドのテキスト内容が一致する。
    |    無     |   無     | なし。（常に偽になります。）

=head4 attributes

=over 4

=item * label (optional)

比較対象のラベルを指定します。

=item * text (optional)

比較したいテキスト内容を指定します。

=back

=head3 MTIfEntryIsDynamic?

エントリのコンテキストで使用します。

そのエントリが動的に生成するものであれば真になります。


=head2 FUNCTIONTAGS

=head3 MTExtFieldCount

エントリのコンテキストで使用します。

そのエントリに紐付く拡張フィールドの数を返します。

=head3 MTExtFieldLabel

拡張フィールドコンテキストで使用します。

その拡張フィールドのラベルを返します。

=head3 MTExtFieldValue

拡張フィールド選択肢コンテキストで使用します。

その選択肢の値を返します。

=head3 MTExtFieldName

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドの識別子を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドの識別子を利用したいときに使用します。

=back

=head3 MTExtFieldText

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドのテキスト内容を返します。

テキスト属性にはタイプ毎に以下の内容が入っています。

    text     | テキスト文字列
    textarea | テキスト文字列(ただしこのタグの出力ではフィルタがあればフィルタされます。)
    radio    | 選択肢の選択中の値
    checkbox | 選択されていれば'1'
    cbgroup  | 選択肢の選択中の値(複数の場合はカンマ区切り)
    select   | 選択肢の選択中の値
    file     | ファイルパス
    date     | YYYYMMDDHHMISS形式の14ケタの数字

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのテキスト内容を利用したいときに使用します。

=item * format (optional)

日付フィールドを処理する際にformat_tsに渡すフォーマットを指定します。

=back

=head3 MTExtFieldCBLabel

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドのチェックボックス表示用ラベルを返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのチェックボックス表示用ラベルを利用したいときに使用します。

=back

=head3 MTExtFieldNum

拡張フィールドコンテキストで使用します。

その拡張フィールドの並び順の番号を返します。

=head3 MTExtFieldFileName

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合ディレクトリを含まないファイル名を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのファイル名を利用したいときに使用します。

=back

=head3 MTExtFieldFilePath

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合ファイルのHTTPから始まるURLを返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのファイルURLを利用したいときに使用します。

=back

=head3 MTExtFieldFileDate

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合ファイルのタイムスタンプを返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのファイルのタイムスタンプを利用したいときに使用します。

=item * format (optional)

タイムスタンプの出力フォーマットを指定します。
(format_tsに渡すフォーマット)

デフォルトはYYYYMMDDHHMISS形式

=back

=head3 MTExtFieldFileSize

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合ファイルサイズを返します。

属性を指定しない場合は、小数点以下1桁までの数値に適切な単位を付けて出力します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのファイルサイズを利用したいときに使用します。

=item * unit (optional)

ファイルサイズの単位を指定します。('kb'または'mb')

この指定がある場合は出力に単位が含まれません。

=item * decimals (optional)

小数点以下何桁を表示するかを数値で指定します。(0以上の整数)

この指定がある場合は出力に単位が含まれません。

=back

=head3 MTExtFieldAlt

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合alt属性値(*)に使われるテキストを返します。
(*)拡張フィールド「ファイル添付」選択後の「名前」欄のテキスト

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのalt属性値を利用したいときに使用します。

=back

=head3 MTExtFieldDescription

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合、拡張フィールド「ファイル添付」選択後の
「説明」欄のテキストを返します。

# TODO 画像の場合は、特別な書き方をすることで画像を埋め込むことが可能？

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドの「説明」欄を利用したいときに使用します。

=back

=head3 MTExtFieldFileSuffix

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドがファイルの場合、ファイルの拡張子を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのファイル拡張子を利用したいときに使用します。

=back

=head3 MTExtFieldImageWidth

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルの場合、ファイルの幅(pixcel値)を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドの画像ファイル幅を利用したいときに使用します。

=back

=head3 MTExtFieldImageHeight

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルの場合、ファイルの高さ(pixcel値)を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドの画像ファイル高さを利用したいときに使用します。

=back

=head3 MTExtFieldThumbnail

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルの場合、サムネイルのURLを返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのサムネイルURLを利用したいときに使用します。

=back

=head3 MTExtFieldThumbnailWidth

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルの場合、サムネイル画像の幅(pixcel値)を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのサムネイル画像ファイル幅を利用したいときに使用します。

=back

=head3 MTExtFieldThumbnailHeight

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルの場合、サムネイル画像の高さ(pixcel値)を返します。

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのサムネイル画像ファイル高さを利用したいときに使用します。

=back

=head3 MTExtFieldsFileThumbnail

拡張フィールドのコンテキストで使用します。
または、label属性を指定してエントリのコンテキストで使用します。

該当拡張フィールドが画像ファイルでサーバにそのファイルが存在する場合、
指定の幅および高さのサムネイル画像を同階層のディレクトリから検索し存在しない
場合は新たに生成の上、そのサムネイル画像のURLを返します。

※このタグはスタティックのみサポートです。

オリジナル画像URLが http://example.com/files/admin/foo.gif の場合の
width属性とheight属性の指定と生成URLの対応は以下の通り

    | width | height | URL
    |   有  |   有   | http://example.com/files/admin/foo-thumb{width}x{height}.gif
    |   有  |   無   | http://example.com/files/admin/foo-thumb{width}x.gif
    |   無  |   有   | http://example.com/files/admin/foo-thumbx{height}.gif
    |   無  |   無   | ''

=head4 attributes

=over 4

=item * label (optional)

拡張フィールドコンテキストかどうかに関わらず、
エントリコンテキスト中で該当拡張フィールドのサムネイル画像URL
(ない場合は生成)を利用したいときに使用します。

=item * width (optional)

サムネイル画像幅を指定します。

=item * height (optional)

サムネイル画像高さを指定します。

=back


=head3 MTExtFieldExportData

拡張フィールドのコンテキストで使用します。

システム内(CMSExporter)で利用。

=head3 MTEntryExtFiles

エントリのコンテキストで使用します。

システム内(CMSExporter)で利用。

=head3 MTEntryExtDatas

エントリのコンテキストで使用します。

システム内(CMSExporter)で利用。


=head3 MTExtFieldID

拡張フィールドのIDを取得。

使用箇所なし。

=head3 MTExtFieldsMultiValue

選択肢系の選択肢を文字列として出力するタグ？
glue属性で区切り文字の指定やactive属性で選択中のものだけを指定ができる。

使用箇所なし。

=head3 MTExtFieldCounter

拡張フィールドコンテキストの現在のループ回数-1を取得。

使用箇所なし。

=head1 MEMO

選択肢系のラベルでは、$extfield->multiple,$extfield->textにはそれぞれカンマ区切りの選択肢が入っていて、textが実際に選択されているもの

ファイル系のラベルでは、$extfield->type には'file'が入るが、$extfield->file_typeに
'image','video','audio','file'が入る、また$extfield->textにファイルパスが入る
$extfield->alternativeにalt属性用の文字列が入る
説明欄用に$extfield->transformが入る

画像ファイル系のラベルでは、$extfield->thumbnailにサムネイルのファイルパスが入る
$extfield->metadataに画像の'幅pixcelサイズ,高さpixcelサイズ'が入る
$extfield->thumb_metadataにサムネイル画像の'幅pixcelサイズ,高さpixcelサイズ'が入る
自動的にできるサムネイル画像は、プラグイン設定で指定の幅を超えているときに作成され、
その幅に等倍縮小で作成される。

textareaラベルでは、$extfield->transformに、text_filter用の数値が入る

    | 2      | MT::Util::html_text_transform
    | 3 - 6  | tab区切りテキストをHTMLテーブル化処理
    | 7,8    | HTMLリスト化処理（ul,ol）
    | 11     | markdown
    | 12     | markdown_with_smartypants
    | 13     | textile_2
    | その他 | フィルタなし

checkboxラベルでは、$extfield->select_itemにチェックボックス用のラベル(チェックボックス右側の表示テキスト,HTMLのlabelタグの中身)が入っている。

=cut
