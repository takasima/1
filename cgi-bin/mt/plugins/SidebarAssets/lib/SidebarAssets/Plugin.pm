package SidebarAssets::Plugin;

use strict;
use File::Spec;
use File::Basename;
use MT::Asset;
use MT::Util qw( decode_url encode_url encode_html );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( save_asset site_path site_url upload is_windows is_cms
                       file_label icon_class get_weblog_ids allow_upload is_image
                       file_basename set_upload_filename uniq_filename
                       charset_is_utf8
                     );

our $plugin_sidebarimage = MT->component( 'SidebarAssets' );

sub _cb_tp_asset_options {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $pointer_field = $tmpl->getElementById( 'extra_options' ) ) {
        my $nodeset = $tmpl->createElement( 'for',
                                            { id => 'extra_options',
                                              label_class => 'no-label',
                                            }
                                          );
        my $innerHTML = <<'MTML';
<__trans_section component="SidebarAssets">
<mt:setvarblock name="label"><__trans phrase="Set Alternate Text"></mt:setvarblock>
<mtapp:setting
    id="alternate_text"
    label="$label"
    label_class="top-label">
    <input type="text" name="alternate_text" id="alternate_text" class="full text" />
</mtapp:setting>
</__trans_section>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer_field );
    }
}

sub _hdlr_sidebar_asset_count {
    my ( $ctx, $args ) = @_;
    my $class = $args->{ 'class' };
    my $blog_id = $args->{ 'blog_id' };
    unless ( $class ) {
        $class = '*';
    }
    my $count = MT->model( 'asset' )->count( { blog_id => $blog_id, class => $class } );
    return $count;
}

sub __upload_files_make_session {
    my ( $upload_token ) = @_;
    require MT::Session;
    return unless ( defined( $upload_token ) && $upload_token ne '' );
    my $sess = MT::Session->load(
        { id => $upload_token, kind => 'UF' }
    );
    return $sess if $sess;
    # new session
    $sess = MT::Session->new();
    $sess->id( $upload_token );
    $sess->kind( 'UF' ); # Upload File
    $sess->start( time );
    $sess->save;
    $sess;
}

sub __upload_files_check_session {
    my ( $upload_token, $file_num ) = @_;
    my $sess = __upload_files_make_session( $upload_token );
    if ( !$sess ) {
        return 'E_MAKE_SESSION';
    }
    if ( my $ses_file_num = $sess->get( 'file_num' ) ) {
        if ( $ses_file_num ne $file_num ) {
            return 'E_INVALID_SESSION';
        }
    }
    else {
        $sess->set( 'file_num', $file_num );
        $sess->save or die $sess->errstr;
    }
    $sess;
}

sub __upload_files_get_session {
    my ( $upload_token ) = @_;
    return unless ( defined( $upload_token ) && $upload_token ne '' );
    require MT::Session;
    return MT::Session::get_unexpired_value(
        15 * 60, { id => $upload_token, kind => 'UF' }
    );
}

sub __upload_files_record_session {
    my ( $app, $session, $msg ) = @_;
    my $key = $app->make_magic_token() . $$; # magic + PID
    $session->set( "msg_$key", $msg );
    $session->save or die $session->errstr;
    return $msg;
}

sub __upload_files_msg_key {
    my ( $session ) = @_;
    my $data = $session->thaw_data;
    return grep { /^msg_/ } keys( %$data );
}

sub __upload_files_polling_phase {
    my ( $app, $upload_token ) = @_;
    my $sess = __upload_files_get_session( $upload_token );
    return 'E_CHECK_TIMEOUT' unless $sess;
    my $data = $sess->thaw_data;
    my $file_num = $data->{ file_num };
    unless ( $file_num ) {
        $sess->remove or die $sess->errstr;
        return 'E_CHECK_INTERNAL';
    }
    my @msg_key = __upload_files_msg_key( $sess );
    if ( $file_num != @msg_key ) {
        return 'E_CHECK_FILE_COUNT';
    }
    $sess->remove or die $sess->errstr;
    for my $key (@msg_key) {
        if ( $data->{ $key } ne 'S_UPLOAD' ) {
            return 'S_CHECK_UPLOAD_SOMEERR';
        }
    }
    return 'S_CHECK_UPLOAD_COMPLETE';
}

sub _upload_files {
    my $app = shift;
    my $upload_token = $app->param( 'upload_token' );
    my $check        = $app->param( 'check' );
    return 'E_INVALID_PARAM' unless $upload_token;
    if ( $check && $check eq '1' ) { # Polling Phase
        return __upload_files_polling_phase( $app, $upload_token );
    }
    # Upload Phase
    my $blog     = $app->blog;
    my $file_num = $app->param( 'file_num' );
    return 'E_INVALID_PARAM' unless $file_num;
    return 'E_NO_BLOG_ID'    unless $blog;
    return 'E_PERMISSION'    unless $app->can_do( 'upload' );
    my $site_path = site_path( $blog, 1 );
    my $scope = 'blog:' . $blog->id;
    my $directory = $plugin_sidebarimage->get_config_value( 'directory', $scope );
    my $rename_file = $plugin_sidebarimage->get_config_value( 'rename_file', $scope );
    my $upload_dir = File::Spec->catdir( $site_path, $directory );
    my $sess = __upload_files_check_session( $upload_token, $file_num );
    return $sess unless ref $sess;
    my @msg_key = __upload_files_msg_key( $sess );
    unless ( @msg_key < $file_num ) {
        return 'E_REQUEST_NUM';
    }
    my ( $res, $err ) = upload(
        $app, $blog, 'Filedata', $upload_dir, { rename => $rename_file, force_decode_filename => 1 }, 1
    );
    my $msg;
    if ( $res ) {
        if ( ref $res eq 'ARRAY' ) {
            if ( @$res ) {
                $msg = 'S_UPLOAD';
            }
            else {
                $msg = 'E_NOFILES';
            }
        }
        else {
            $msg = 'E_UNKNOWN';
        }
    }
    else {
        my %errmsg_of = qw( 1 E_FILESIZE );
        $msg = 'E_UNKNOWN';
        $msg = $errmsg_of{ $err } if exists $errmsg_of{ $err };
    }
    return __upload_files_record_session( $app, $sess, $msg );
}

sub _build_preview {
    my ( $eh, %args ) = @_;
    my $app = MT->instance();
    my $archive_type = $args{ 'archive_type' };
    return unless ( $archive_type eq 'preview' );
    my $blog = $args{ 'blog' };
    my $content = $args{ 'content' };
    my $get_from = 'blog:'. $blog->id;
    my $rel2abs = $plugin_sidebarimage->get_config_value( 'rel2abs', $get_from );
    if ( ( ( $app->param( 'convert_breaks' ) ) && ( $rel2abs == 1 ) )
        || ( $rel2abs == 2 ) ) {
        my $content = $args{ 'content' };
        my $file = $args{ 'file' };
        my $site_path = site_path( $blog );
        my $site_url  = site_url( $blog );
        my $abs_path  = $site_url;
        $abs_path =~ s{^(?i:https?)://[^/]+}{};
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
        my $dir = File::Basename::dirname( $file );
        my $match = '<[^>]+\s(src|href|action)\s*=\s*\"';
        my @org_asset; my @save_asset;
        my $obj = MT::Entry->new;
        $$content =~ s/($match)(.{1,}?)(")/$1.&_check_asset(
                     $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                     $doc_root, 0, \@org_asset, \@save_asset
                 ).$4/esg;
    }
}

sub _parse_asset {
    my ( $eh, $app, $obj, $original ) = @_;
    return 1 unless is_cms( $app );
    my $blog = $obj->blog;
    my $site_path = site_path( $blog, 1 );
    my $site_url = site_url( $blog );
    my $abs_path = $site_url;
    $abs_path =~ s{^(?i:https?)://[^/]+}{};
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
    my $file = $obj->archive_file();
    $file = File::Spec->catfile( $site_path, $file );
    require File::Basename;
    my $dir = File::Basename::dirname( $file );
    my $match = '<[^>]+\s(src|href|action)\s*=\s*\"';
    my $get_from = 'blog:'. $blog->id;
    my $rel2abs = $plugin_sidebarimage->get_config_value( 'rel2abs', $get_from );
    my @org_asset; my @save_asset;
    if ( defined $original ) {
        my $org_text = $original->text;
        $org_text =~ s/($match)(.{1,}?)(")/$1.&_check_asset(
                     $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                     $doc_root, 0, \@org_asset, \@save_asset
                 ).$4/esg;
        my $org_more = $original->text_more;
        $org_more =~ s/($match)(.{1,}?)(")/$1.&_check_asset(
                     $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                     $doc_root, 0, \@org_asset, \@save_asset
                 ).$4/esg;
    }
    my $text = $obj->text;
    $text =~ s/($match)(.{1,}?)(")/$1.&_check_asset(
                 $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                 $doc_root, 1, \@org_asset, \@save_asset
             ).$4/esg;
    my $text_more = $obj->text_more;
    $text_more =~ s/($match)(.{1,}?)(")/$1.&_check_asset(
                 $app, $blog, $obj, $3, $dir, $site_path, $site_url,
                 $doc_root, 1, \@org_asset, \@save_asset
             ).$4/esg;
    if ( defined $original ) {
        for my $objectasset ( @org_asset ) {
            my $oid = $objectasset->id;
            unless ( grep( /^$oid$/, @save_asset ) ) {
                $objectasset->remove or die $objectasset->errstr;
            }
        }
    }
    if ( ( ( $obj->convert_breaks eq 'richtext' ) && ( $rel2abs == 1 ) )
        || ( $rel2abs == 2 ) ) {
        if ( $obj->text ne $text ) {
            $obj->text( $text );
        }
        if ( $obj->text_more ne $text_more ) {
            $obj->text_more( $text_more );
        }
    }
    1;
}

sub _check_asset {
    my ( $app, $blog, $obj, $src, $file, $site_path,
         $site_url, $doc_root, $save, $org_asset, $save_asset ) = @_;
    my $path = $src;
    my $full_path;
    if ( ( $path =~ m!^\.\./! ) || ( ( $path !~ /^\// ) && ( $path !~ /^http/ ) ) ) {
        my $url_encoded = 0;
        $path = File::Spec->rel2abs( $path, $file );
        unless ( -f $path ) {
            $url_encoded = 1;
            $path = decode_url( $path );
        }
        unless ( -f $path ) {
            $url_encoded = 0;
            $path = File::Spec->rel2abs( $src, $app->document_root. $app->path );
        }
        unless ( -f $path ) {
            $url_encoded = 1;
            $path = decode_url( $path );
        }
        unless ( -f $path ) {
            $url_encoded = 0;
            my $parent_path = '../';
            my $q_parent_path = quotemeta( $parent_path );
            my $temp_src = $src;
            my $parent_num = $temp_src =~ s/$q_parent_path//g;
            my $app_path = $app->base . $app->path;
            $app_path =~ s/\/$//;
            my @items = split( /\//, $app_path );
            my $file_url;
            for ( my $i = 0; $i < ( scalar @items ) - $parent_num; $i++ ) {
                $file_url .= $items[ $i ];
                $file_url .= '/';
            }
            $file_url .= $temp_src;
            my $q_site_url = quotemeta( $site_url );
            if ( $file_url =~ /$q_site_url(.*)$/ ) {
                $path = $site_path . $1;
            }
        }
        unless ( -f $path ) {
            $url_encoded = 1;
            $path = decode_url( $path );
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
        my $q_site_path = quotemeta( $site_path );
        return $src unless $path =~ /$q_site_path/;
        $full_path = $path;
        if ( $url_encoded ) {
            my ( $v, $d, $f ) = File::Spec->splitpath( $path );
            $path = File::Spec->catpath( $v, $d, encode_url( $f ) );
        }
        $path =~ s/$site_path/%r/;
    } elsif ( $path =~ /^$site_url/ ) {
        $path =~ s/$site_url/%r/;
        $full_path = $path;
        $full_path =~ s/%r/$site_path/;
    } elsif ( $path =~ m!^/(.*)! ) {
        $path = File::Spec->catfile ( $doc_root, $1 );
        my $q_site_path = quotemeta( $site_path );
        return $src unless $path =~ /$q_site_path/;
        $full_path = $path;
        $path =~ s/$site_path/%r/;
    }
    if ( $full_path ) {
        if ( -f $full_path && allow_upload( $full_path ) ) {
            require MT::FileInfo;
            my $fileinfo = MT::FileInfo->load( { file_path => $full_path } );
            unless ( defined $fileinfo ) {
                if ( is_windows() ) {
                    my $q_site_path = quotemeta( $site_path );
                    $path =~ s/$q_site_path/%r/;
                }
                my $asset = __load_asset( $blog, $path, $site_url );
                unless ( defined $asset ) {
                    my $get_from = 'blog:'. $blog->id;
                    my $create_asset = $plugin_sidebarimage->get_config_value( 'create_asset', $get_from );
                    if ( $create_asset ) {
                        my $not_import = $plugin_sidebarimage->get_config_value( 'not_import', $get_from );
                        my @extension = split ( /,/, $not_import );
                        for my $ext ( @extension ) {
                            if ( $path =~ /$ext$/ ) {
                                $create_asset = 0;
                            }
                        }
                        my %params = (
                            'file' => $full_path,
                            'object' => $obj,
                            'author_id' => ( ref $app eq 'MT::App::CMS' ? $app->user->id : $obj->author_id ),
                        );
                        $asset = &save_asset( $app, $blog, \%params, 1 ) if $create_asset;
                    }
                }
                if ( defined $asset ) {
                    require MT::ObjectAsset;
                    my $objectasset = MT::ObjectAsset->get_by_key( { asset_id => $asset->id,
                                                                     object_id => $obj->id,
                                                                     object_ds => 'entry',
                                                                     blog_id => $blog->id
                                                                    } );
                    unless ( $objectasset->id ) {
                        if ( $save ) {
                            $objectasset->save
                                    or return $app->trans_error( 'Error saving objectasset: [_1]', $objectasset->errstr );
                        }
                    } else {
                        if ( $save ) {
                            push ( @{$save_asset}, $objectasset->id );
                        } else {
                            push ( @{$org_asset}, $objectasset );
                        }
                    }
                }
            }
        }
    }
    if ( $path =~ /^%r/ ) {
        $path =~ s/%r/$site_url/;
        if ( $^O eq 'MSWin32' ) {
            $path =~ s!\\!/!g;
        }
        return $path;
    } else {
        return $src;
    }
    return $src;
}

sub __load_asset {
    my ( $blog, $path, $site_url ) = @_;
    require MT::Asset;
    if ( $blog->is_blog ) {
        my $asset = MT::Asset->load( {
            blog_id => $blog->id,
            class   => '*',
            url     => $path,
        } );
        return $asset;
    }
    # Website
    my $abs_url = $path;
    $abs_url =~ s/%r/$site_url/;
    my $file = $path;
    if ( $file =~ m/([^\/]+)$/ ) {
        $file = $1;
    }
    else {
        return;
    }
    my @ids = get_weblog_ids( $blog );
    my @asset = MT::Asset->load( {
        blog_id   => \@ids,
        class     => '*',
        file_name => $file,
    } );
    unless ( @asset ) {
        @asset = MT::Asset->load( {
            blog_id   => \@ids,
            class     => '*',
            file_name => decode_url( $file ),
        } );
    }
    foreach my $a ( @asset ) {
        if ( $a->url eq $abs_url ) {
            return $a;
        }
    }
    return;
}

sub _sidebarimage_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $static_uri = $app->static_path;
    my $src = $app->base . $static_uri . 'images/indicator.gif';
    my $icon_rem = $static_uri . 'images/status_icons/error.gif';
    my $append = <<MTML;
<mt:setvarblock name="related_content" prepend="1">
<div class="widget pkg customfields-reorder-widget">
    <div class="widget-inner inner">
        <div class="widget-header ">
            <div class="widget-header-inner pkg">
                <h3 class="widget-label"><a id="sidebar-image-widget" href="javascript:void(0)" onclick="toggle_canvas();return false;"><span><__trans phrase="Image"></span></a></h3>
            </div>
        </div>
    </div>
    <mt:if name="can_upload">
    <div class="widget-content" id="create_sidebar_image">
        <div class="widget-content-inner">
            <p class="create-link" id="create-link"><a class="icon-left icon-create"
            href="javascript:void(0);"
            onclick="toggle_append_image();return false;"
            ><__trans phrase="Create"></a></p>
        </div>
    </div>
    </mt:if>
</div>

<div style="margin-bottom:12px; display:none;" id="image_canvas">
    <iframe id="canvas-iframe" height="300" frameborder="0"></iframe>
</div>

<script type="text/javascript">
    var isIE = (document.documentElement.getAttribute("style") == document.documentElement.style);
    var loaded;
    var flds = 1;
    function toggle_canvas () {
        var canvas = document.getElementById( 'image_canvas' );
        if ( canvas.style.display == 'none' ) {
            if ( ! loaded ) {
                try {
                    appendHTML( 'canvas-iframe', '$src' );
                } catch (e) {
                }
                var rnd = Math.random();
                document.getElementById( 'canvas-iframe' ).src = '<mt:var name="script_url">?__mode=sidebarimage&amp;blog_id=<mt:var name="blog_id">&amp;offset=0&amp;key=' + rnd;
                loaded = 1;
            }
            canvas.style.display='block';
            document.getElementById( 'create_sidebar_image' ).style.display = 'block';
            document.getElementById( 'sidebar-image-widget' ).style.backgroundImage = 'url(<mt:var name="static_uri">images/spinner-bottom.gif)';
        } else {
            canvas.style.display='none';
            document.getElementById( 'create_sidebar_image' ).style.display = 'none';
            document.getElementById( 'sidebar-image-widget' ).style.backgroundImage = 'url(<mt:var name="static_uri">images/spinner-right.gif)';
        }
    }
    function iframeDoc( id ) {
        if ( isIE ) {
            return frames[id].document;
        }
        return document.getElementById(id).contentDocument;
    }
    function appendHTML( iframeid, src ) {
        var doc = iframeDoc( iframeid );
        var container = doc.createElement("div");
        container.style.height = '165px';
        container.style.backgroundImage = 'url("' + src + '")';
        container.style.backgroundRepeat = 'no-repeat';
        container.style.backgroundPosition = 'center bottom';
        doc.body.appendChild(container);
    }
    function toggle_append_image () {
        var doc = iframeDoc( 'canvas-iframe' );
        var ele = doc.getElementById( 'append_image' );
        ele.style.display = 'block';
        ele = doc.getElementById( 'sidebar_image_block' );
        var block = doc.createElement( 'div' );
        block.setAttribute( 'id', 'sidebar_block_' + flds );
        var label = doc.createElement( 'label' );
        var label_val = doc.createTextNode( '<__trans phrase="Name">  ' );
        label.appendChild( label_val );
        var rem = doc.createElement( 'a' );
        rem.setAttribute( 'href', 'javascript:void(0)' );
        var func = 'rem_fld("'+flds+'")\;return false\;';
        if ( isIE ){
            rem.setAttribute( 'onclick', new Function(func) );
        } else {
            rem.setAttribute( 'onclick', func );
        }
        var icon_rem = doc.createElement( 'img' );
        icon_rem.setAttribute( 'src', '$icon_rem' );
        rem.appendChild( icon_rem );
        label.appendChild( rem );
        label.setAttribute( 'for', 'sidebar_name_' + flds );
        block.appendChild( label );
        var wrapper = doc.createElement( 'div' );
        wrapper.className = 'textarea-wrapper';
        var field = doc.createElement( 'input' );
        field.className = 'sidebar_name';
        field.setAttribute( 'id', 'sidebar_name_' + flds );
        field.setAttribute( 'name', 'sidebar_name_' + flds );
        field.setAttribute( 'type', 'text' );
        wrapper.appendChild( field );
        block.appendChild( wrapper );
        para = doc.createElement( 'p' );
        field = doc.createElement( 'input' );
        field.className = 'sidebar_image';
        field.setAttribute( 'id', 'sidebar_image_' + flds );
        field.setAttribute( 'name', 'sidebar_image_' + flds );
        field.setAttribute( 'type', 'file' );
        para.appendChild( field );
        block.appendChild( para );
        ele.appendChild( block );
        var doc_flds = doc.getElementById( 'flds' );
        if ( doc_flds.value != '' ) {
            doc_flds.value = eval(doc_flds.value) + 1;
        } else {
            doc_flds.value = 1;
        }
        var focus_fld = doc.getElementById( 'sidebar_name_' + flds );
        focus_fld.focus();
        flds++;
    }
</script>
</mt:setvarblock>

<mt:setvarblock name="html_head" append="1">
<style type="text/css">
#create_sidebar_image {
    display: none;
}
#sidebar-image-widget {
    background: url(<mt:var name="static_uri">images/spinner-right.gif) no-repeat left center;
    padding-left: 11px;
}
</style>
</mt:setvarblock>
<mt:include name="include/header.tmpl" id="header_include">
MTML
    my $include = '<mt:include name="include/header.tmpl" id="header_include">';
    my $old = quotemeta($include);
    $$tmpl =~ s/$old/$append/;
}

sub _edit_asset_dialog {
    my ($cb, $app, $tmpl) = @_;
    my $q = $app->param;
    my $flag = $q->param( 'sidebar' );
    if ( $flag ) {
        my $include = '<mt:include name="include/header.tmpl">';
        my $dialog = '<mt:include name="dialog/header.tmpl">';
        $dialog .= '<div style="width:80%">';
        $$tmpl =~ s/$include/$dialog/;
        $dialog = '<mt:include name="dialog/footer.tmpl">';
        $include = '<mt:include name="include/footer.tmpl">';
        $$tmpl =~ s/$include/$dialog/;
        my $button = '<__trans phrase="Save Changes">.*?</button>';
        my $cancel = <<BUTTON;
        <button
            type="submit"
            accesskey="x"
            class="button action mt-close-dialog"
            title="<__trans phrase="Cancel"> (x)"
            ><__trans phrase="Cancel"></button>
BUTTON
        $$tmpl =~ s/($button)/$1$cancel/s;

        my $search = quotemeta(q{<mt:var name="return_args" escape="html">});
        my $inseart = '&amp;sidebar=1';
        $$tmpl =~ s/($search)/$1$inseart/;

        $search = quotemeta(q{<form id="edit_asset" method="post" action="<mt:var name="script_url">">});
        $inseart = '<mt:if name="saved"><script type="text/javascript">parent.asset_list.reload(); parent.jQuery.fn.mtDialog.close();</script></mt:if>';
        $$tmpl =~ s/($search)/$inseart$1/;

    }
}

sub _edit_asset_output {
    my ($cb, $app, $tmpl) = @_;
    my $q = $app->param;
    my $icon = $app->static_path . 'images/asset/file.gif';
    my $icon_v = $app->static_path . 'images/asset/video.gif';
    my $icon_a = $app->static_path . 'images/asset/audio.gif';
    my $flag = $q->param( 'sidebar' );
    if ( $flag ) {
        my $head = '</head>';
        my $css .= <<"CSS";
<style type="text/css">
.asset-thumb-metadata {background-color:white;text-align:center}
.asset-type-image {background-color:transparent !important}
.asset-type-file {background-color:transparent !important}
.asset-type-video {background-color:transparent !important}
.asset-type-audio {background-color:transparent !important}
.asset-type-image .asset-thumb-inner{ background-color:black;text-align:center }
.asset-type-file .asset-thumb-inner { height:250px;text-indent:-10000px; background-color:#EEEEEE;
                                      background-image:url($icon);
                                      background-repeat:no-repeat;
                                      background-position:120px 120px;
                                      border:1px solid gray; }
.asset-type-video .asset-thumb-inner{ height:250px;text-indent:-10000px; background-color:#EEEEEE;
                                      background-image:url($icon_v);
                                      background-repeat:no-repeat;
                                      background-position:120px 120px;
                                      border:1px solid gray; }
.asset-type-audio .asset-thumb-inner{ height:250px;text-indent:-10000px; background-color:#EEEEEE;
                                      background-image:url($icon_a);
                                      background-repeat:no-repeat;
                                      background-position:120px 120px;
                                      border:1px solid gray; }
</style>
</head>
CSS
        $$tmpl =~ s/$head/$css/;
        my $return_args = '<input type="hidden" name="return_args" value="';
        $$tmpl =~ s/($return_args.*?)"/$1&amp;dialog=1"/;
    }
}

sub _asset_insert_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $upload_html = $param->{ upload_html }
        or return;
    my $key = 'alternate_text';
    my $alt = defined $app->param($key) && $app->param($key) =~ /\S/
            ? MT::Util::encode_html($app->param($key)) : '';
    $upload_html =~ s/(?<=\salt=")[^"]*/$alt/i;
    $param->{ upload_html } = $upload_html;
}

sub _cb_post_save_author {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( $app->mode eq 'save' ) {
        my $use_drag_drop = $app->param( 'use_drag_drop' );
        $obj->use_drag_drop( $use_drag_drop );
        $obj->save or die $obj->errstr
    }
    return 1;
}

sub _cb_param_edit_author {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $use_drag_drop;
    if ( $app->param( 'id' ) ) {
        my $author = MT::Author->load( $app->param( 'id' ) );
        $use_drag_drop = $author->use_drag_drop;
        if ( $use_drag_drop ) {
            $param->{ use_drag_drop } = 1;
        }
    }
    my $pointer_field = $tmpl->getElementById( 'email' );
    my $nodeset = $tmpl->createElement( 'app:setting',
                                        { id => 'use_drag_drop',
                                        label => $plugin_sidebarimage->translate( 'DropBox' ),
                                        required => 0 } );
    my $innerHTML = '<label><input type="checkbox" name="use_drag_drop" id="use_drag_drop" value="1" <mt:if name="use_drag_drop">checked="checked"</mt:if> /> ';
    $innerHTML .= $plugin_sidebarimage->translate( 'Enable DropBox' ) . '<input type="hidden" name="use_drag_drop" value="0" /></label>';
    $nodeset->innerHTML ( $innerHTML );
    $tmpl->insertAfter ( $nodeset, $pointer_field );
}

sub _sidebarimage {
    my $app = shift;
    my $q = $app->param;
    my $blog_id = $q->param( 'blog_id' );
    my $blog = $app->blog;
    my $site_path = site_path( $blog, 1 );
    my $site_url = site_url( $blog );
    my $offset = $q->param( 'offset' );
    my $limit = $q->param( 'limit' );
    my $class = $q->param( 'class' );
    my $type = $q->param( 'type' );
    my $delete_id = $q->param( 'delete_id' );
    my $get_from = 'blog:' . $blog_id;
    if ( $type && ( $type eq 'upload') ) {
        unless ( $app->can_do( 'upload' ) ) {
            return 1;
        }
        my $directory = $plugin_sidebarimage->get_config_value( 'directory', $get_from );
        my $rename_file = $plugin_sidebarimage->get_config_value( 'rename_file', $get_from );
        for my $key ( $q->param ) {
            if ( $key =~ /^sidebar_image_([0-9]{1,})$/ ) {
                my $num = $1;
                my $fmgr = $blog->file_mgr;
                my $file = $q->upload( 'sidebar_image_' . $num );
                if ( $file && allow_upload( $file ) ) {
                    { # check
                        my $check_filename = $file;
                        $check_filename = decode_url( $check_filename );
                        $check_filename =~ s/%2[Ee]/\./g;
                        if ( $check_filename =~ m!\.\.|\0|\|! ) {
                            return 0;
                        }
                    }
                    my $label = file_label( $q->param( 'sidebar_name_' . $num ) );
                    my $filename = ( MT->config( 'NoDecodeFilename' ) ? file_basename( $file ) : set_upload_filename( $file ) );
                    my $out = File::Spec->catfile( $site_path, $directory, $filename );
                    if ( charset_is_utf8() ) {
                        $out = Encode::decode_utf8( $out );
                    }
                    $out = uniq_filename( $out, { no_decode => 1, } ) if $rename_file; # if decoding is needed, file name is decoded at previous line.
                    require File::Basename;
                    my $dir = File::Basename::dirname( $out );
                    $dir =~ s!/$!! unless $dir eq '/';
                    unless ( $fmgr->exists( $dir ) ) {
                        $fmgr->mkpath( $dir );
                    }
                    my $temp = "$out.new";
                    local *OUT;
                    my $umask = $app->config( 'UploadUmask' );
                    my $old = umask( oct $umask );
                    open ( OUT, ">$out" ) or die "Can't open $out!";
                    binmode ( OUT );
                    while( read ( $file, my $buffer, 1024 ) ) {
                        print OUT $buffer;
                    }
                    close ( OUT );
                    $fmgr->rename( $temp, $out );
                    umask( $old );
                    my $fullpath = $out;
                    $out =~ s/$site_path/%r/;
                    my %asset_elements = (
                        'file' => $fullpath,
                        'blog_id' => $blog->id,
                        'label' => $label,
                        'author' => $app->user,
                    );
                    my $asset = &save_asset( $app, $blog, \%asset_elements, 1 );
                }
            }
        }
        if ( my $return_url = $app->param( 'return_url' ) ) {
            return $app->redirect( $return_url );
        } else {
            return 0;
        }
    }
    if ( $offset !~ /[0-9]+/ ) {
        $offset = 0;
    }
    if (! $class || $class eq 'all' ) {
        $class = '*';
    }
    unless ( $limit ) {
        $limit = $plugin_sidebarimage->get_config_value( 'limit', $get_from );
    }
    if ( $delete_id ) {
        $limit = $limit + 1;
    }
    my $count = MT->model( 'asset' )->count( { blog_id => $blog_id, class => $class } );
    my $no_thumbnails;
    if ( my $plugin_mobile = MT->component( 'Mobile' ) ) {
        $no_thumbnails = $plugin_mobile->get_config_value( 'not_show_other_fomatted_images', 'blog:' . $blog_id );
    }
    my $iter = MT->model( 'asset' )->load_iter( { blog_id => $blog_id,
                                                  class => $class,
                                                  ( $no_thumbnails ? ( parent => \'is NULL' ) : () ),
                                                }, {
                                                  offset    => $offset,
                                                  limit     => $limit,
                                                  sort      => 'modified_on',
                                                  direction => 'descend'
                                                }
                                              );
    my %param;
    my @asset_loop; my $odd = 1; my $i = 1;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin_sidebarimage->path,'tmpl' );
    while ( my $asset = $iter->() ) {
        my $asset_path = $asset->file_path;
        $asset_path =~ s/^%r/$site_path/;
        if ( -f $asset_path ) {
            my $asset_url = $asset->url;
            my $asset_name = $asset->label;
            $asset_name = $asset->file_name unless ( $asset_name );
            my ( $asset_class, $asset_ext, $icon_class );
            $asset_class = $asset->class;
            $asset_ext   = $asset->file_ext;
            $icon_class  = icon_class( $asset_class, $asset_ext );
            my ( $width, $height, $thumb_w, $thumb_h );
            if ( $asset->class eq 'image' ) {
                $width = $asset->image_width;
                $height = $asset->image_height;
                $thumb_w = $width;
                $thumb_h = $height;
                my $max_length = 54;
                if ( $width == $height ) {
                    if ( $width > $max_length ) {
                        $thumb_w = $max_length;
                        $thumb_h = $max_length;
                    }
                } elsif ( $width < $height ) {
                    if ( $height > $max_length ) {
                        $thumb_h = $max_length;
                        my $scale = $max_length / $height;
                        $thumb_w = $width * $scale;
                        $thumb_w = int( $thumb_w );
                    }
                } else {
                    if ( $width > $max_length ) {
                        $thumb_w = $max_length;
                        my $scale = $max_length / $width;
                        $thumb_h = $height * $scale;
                        $thumb_h = int( $thumb_h );
                    }
                }
            }
            push @asset_loop,
                {
                    asset_name    => $asset_name,
                    asset_label   => $asset->label,
                    ( $asset->class eq 'image' ? ( asset_width  => $width ) : () ),
                    ( $asset->class eq 'image' ? ( asset_height => $height ) : () ),
                    ( $asset->class eq 'image' ? ( thumb_width  => $thumb_w ) : () ),
                    ( $asset->class eq 'image' ? ( thumb_height => $thumb_h ) : () ),
                    asset_url     => $asset->url,
                    asset_num     => $i,
                    asset_id      => $asset->id,
                    asset_class   => $asset_class,
                    asset_mime_type => $asset->mime_type,
                    asset_ext     => $asset_ext,
                    ( $icon_class ? ( icon_class => $icon_class ) : () ),
                    page_class    => $class,
                    odd => $odd,
                };
            if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
            $i++;
        }
    }
    my $tmpl;
    $tmpl = 'SidebarAssets_list.tmpl';
    $param{ 'offset' } = $offset;
    if ( $offset ) {
        my $prev_offset = $offset - $limit;
        if ( $prev_offset > -1 ) {
            $param{ 'prev_offset' } = 1;
            $param{ 'prev_offset_val' } = $prev_offset;
        }
    }
    $param{ 'list_total' } = $count;
    $param{ 'list_start' } = $offset + 1;
    my $list_end = $offset + $i - 1;
    $param{ 'list_end' } = $list_end;
    if ( $list_end < $count ) {
        $param{ 'next_offset' } = 1;
        $param{ 'next_offset_val' } = $offset + $limit;
        $param{ 'next_max' } = $count - $limit;
    }
    $param{ 'asset_loop' } = \@asset_loop;
    if ( $delete_id ) {
        $param{ 'delete_id' } = $delete_id;
    }
    return $app->build_page( $tmpl, \%param );
}

sub _file_name {
    my $file = shift;
    $file =~ s/\\/\//g;
    $file =~ s/://g;
    if ( $file =~ /\// ) {
        my @pathes = split( /\//, $file );
        $file = pop(@pathes);
    }
    my $_ctext = encode_url( $file );
    if ($_ctext ne $file) {
        my @suffix = split( /\./, $file );
        my $ext = pop(@suffix);
        my $ext_len = length($ext) + 1;
        require Digest::MD5;
        $file = Digest::MD5::md5_hex($file);
        $file = substr ( $file, 0, 255 - $ext_len );
        $file .= '.' . $ext;
    }
    return $file;
}

sub _uniq_filename {
    my $file = shift;
    my @suffix = split( /\./,$file );
    my $ext = pop( @suffix );
    my $base = $file;
    $base =~ s/(.{1,})\.$ext$/$1/;
    my $i = 0;
    do {
            $i++;
            $file = $base.'_'.$i.'.'.$ext;
        } while (-e $file);
    return $file;
}

1;

__END__

=head2 _upload_files

upload_filesモードのモードハンドラで、サイドバーのJavaScript側とのインターフェース

アップロードフェーズでは、ファイルをアップして処理結果を文字列で返します。
ポーリングフェーズでは、現在の処理状況を文字列で返します。

check=1があるとポーリングフェーズ、ないとアップロードフェーズとして処理します。

以下のパラメータを受け取ります。

=over 4

=item * upload_token ( required )

ファイルアップロードセッションを特定するキー

=item * file_num ( required* )

アップロードフェーズのときは必須、総アップロードファイル数

=item * blog_id ( required* )

アップロードフェーズのときは必須、ブログID

=item * Filedata ( required* )

フォームのfile属性

=item * check ( optional )

ポーリングフェーズを処理させるフラグ（1のときポーリングフェーズ）

=back

=head3 アップロードフェーズの戻り値

=over 4

=item * E_INVALID_PARAM

upload_token,file_numが存在しない

=item * E_NO_BLOG_ID

blog_idが存在しない

=item * E_PERMISSION

権限がない

=item * E_MAKE_SESSION

セッションの作成、取得に失敗

=item * E_INVALID_SESSION

セッションに保持されたfile_numがクエリと一致しない

=item * E_NOFILES

ファイルが存在しない

=item * E_FILESIZE

ファイルサイズエラー

これはほとんどのケースで発生する前にMTのエラー画面になる。
file属性に複数渡したときの合計値が超えるとエラーになるが、
現在のAjax側の処理では複数渡さないので関係ない。

=item * E_UNKNOWN

未定義のエラー

=item * S_UPLOAD

アップロード成功

=back

=head3 ポーリングフェーズの戻り値

=over 4

=item * E_INVALID_PARAM

upload_tokenが存在しない

=item * E_CHECK_TIMEOUT

セッションタイムアウト（または既にセッションがない）

最初のセッション作成から15分を超えると発生

=item * E_CHECK_INTERNAL

セッション中にfile_numが存在しない

通常ありえないはず

=item * E_CHECK_FILE_COUNT

まだすべてのアップロードが済んでいない

=item * S_CHECK_UPLOAD_SOMEERR

すべてのファイルは処理済みだが、成功していないものがある

=item * S_CHECK_UPLOAD_COMPLETE

すべてのファイルは正常に処理が終了した

=back

=cut
