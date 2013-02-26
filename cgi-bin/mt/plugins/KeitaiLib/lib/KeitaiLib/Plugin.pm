package KeitaiLib::Plugin;

use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( site_path site_url file_extension file_label is_application write2file );

use Encode qw( encode );

our $plugin_keitailib = MT->component( 'KeitaiLib' );

sub _archetype_editor {
    my ( $cb, $app, $tmpl ) = @_;
    my $search = quotemeta( '<span class="add-enclosure">' );
    my $edit_field = '';
    my $tinymce = MT->component( 'TinyMCE' );
    if ( $tinymce ) {
        $edit_field = '&amp;edit_field=editor-content-textarea';
    }
    my $add_button = <<MTML;
                                <span class="add-enclosure">
                                <__trans_section component="KeitaiLib">
                                    <a href="<mt:var name="static_uri">plugins/KeitaiLib/emoticons.php?size=<mt:KeitaiEmoticonSize escape="html">&amp;lang=<mt:var name="local_lang_id">$edit_field"
                                       title="<__trans phrase="Insert Emoji" escape="html">"
                                       style="background-image:url('<mt:var name="static_uri">/plugins/KeitaiLib/images/button_emoji.gif');background-position:0px;4px;"
                                       class="insert-emoticon toolbar button mt-open-dialog"><mt:if tag="version" like="/^5\.0/"><b><mt:else><span class="button-label"></mt:if><__trans phrase="Insert Emoji" escape="html"><mt:if tag="version" like="/^5\.0/"></b><s></s><mt:else></span></mt:if></a>
                                </__trans_section>
MTML
    $$tmpl =~ s/$search/$add_button/;
}

sub _build_page {
    my ( $eh, %args ) = @_;
    my $tmpl = $args{ Template };
    if ( $tmpl && $tmpl->has_column( 'shift_jis' ) ) {
        if ( $tmpl->shift_jis ) {
            my $app = MT->instance;
            my $charset = $app->{ cfg }->PublishCharset;
            my $encoding = lc ( $charset );
            $encoding =~ tr/-_//d;
            if ( $encoding ne 'shiftjis' ) {
                my $content = $args{ Content };
                $$content = encode( 'cp932', $$content, Encode::FB_HTMLCREF );
            }
        }
    }
}

sub _build_file_filter {
    my ( $eh, %args ) = @_;
    my $blog = $args{ Blog };
    my $file = $args{ File };
    my $ctx  = $args{ Context };
    my $fi   = $args{ FileInfo };
    my $tmpl = $args{ Template };
    my $url  = $fi->url;
    my $site_path = site_path( $blog );
    my $site_url  = site_url( $blog );
    $site_url =~ s!(^https?://.*?)/(.*$)!$1!;
    $url = $site_url . $url;
    $ctx->stash( 'current_archive_url', $url );
    my $file_label = file_label( $file );
    my $file_extension = file_extension( $file );
    my $file_number = $ctx->stash( 'current_archive_number' );
    $file_number = 1 unless $file_number;
    my $current_archive_base = $file;
    my $basename_prefix = $plugin_keitailib->get_config_value( 'basename_prefix' );
    $basename_prefix = quotemeta( $basename_prefix );
    $current_archive_base =~ s/$basename_prefix$file_number\.$file_extension$//i if ( $file_number > 1 );
    $current_archive_base =~ s/\.$file_extension$// if ( $file_number == 1 );
    $ctx->stash( 'current_archive_number', $file_number );
    $ctx->stash( 'current_archive_base', $current_archive_base );
    $ctx->stash( 'current_file_info', $fi );
    $ctx->stash( 'current_file_template', $tmpl );
    $ctx->stash( 'current_file_ctx', $ctx );
    $ctx->stash( 'current_file_args', \%args );
    return 1;
}

sub _build_dynamic {
    # for MT 5.02
    my ( $eh, %args ) = @_;
    my $file = $args{ File };
    my $fi   = $args{ FileInfo };
    if (-f $file ) {
        require MT::FileInfo;
        my @finfos = MT::FileInfo->load( { original_fi_id => $fi->id, } );
        for my $finfo ( @finfos ) {
            my $file_path = $finfo->file_path;
            if ( -f $file_path ) {
                unlink $file_path;
            }
            $finfo->remove or die $finfo->errstr;
        }
    }
    return 1;
}

sub _post_delete_archive_file {
    my ( $cb, $file, $at, $entry ) = @_;
    require MT::FileInfo;
    if ( my $fi = MT::FileInfo->load( { file_path => $file } ) ) {
        if ( $fi ) {
            my @finfos = MT::FileInfo->load( { original_fi_id => $fi->id, } );
            for my $finfo ( @finfos ) {
                my $file_path = $finfo->file_path;
                if ( -f $file_path ) {
                    unlink $file_path;
                }
                $finfo->remove or die $finfo->errstr;
            }
        }
    }
}

sub _cb_tp_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $at = $param->{ type };
    my $pointer_field;
    if ( $at eq 'index' ) {
        $pointer_field = $tmpl->getElementById( 'identifier' );
    } else {
        $pointer_field = $tmpl->getElementById( 'archive_mapping' );
    }
    if ( $pointer_field ) {
        my $nodeset = $tmpl->createElement( 'app:setting', { id => 'shift_jis',
                                                             label => $plugin_keitailib->translate( 'Encoding' ),
                                                             label_class => 'top-level',
                                                             required => 0,
                                                           }
                                          );
        my $innerHTML = <<'MTML';
<__trans_section component="KeitaiLib">
<label>
    <input name="shift_jis" id="shift_jis" type="checkbox" <mt:if name="shift_jis">checked="checked"</mt:if> value="1" /> <__trans phrase="Convert this archive to Shift_JIS">
    <input name="shift_jis" type="hidden" value="0" />
</label>
</__trans_section>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertBefore( $nodeset, $pointer_field );
    }
}

sub _cb_restore {
    my $self = shift;
    my ( $all_objects, $callback, $errors ) = @_;

    my $error_object_count = 0;

    for my $key ( keys %$all_objects ) {
        if ( $key =~ /^MT::FileInfo#(\d+)$/ ) {
            my $fileinfo = $all_objects->{$key};
            if ( my $original_fi_id = $fileinfo->original_fi_id ) {
                my $new_fileinfo = $all_objects->{ 'MT::FileInfo#' . $original_fi_id };
                if ( $new_fileinfo ) {
                    $fileinfo->original_fi_id( $new_fileinfo->id );
                } else {
                    $fileinfo->original_fi_id( 0 );
                    $error_object_count = $error_object_count + 1;
                }
                $fileinfo->update();
            }
        }
    }
    if ( $error_object_count ) {
        push( @$errors,
            MT->translate( 'Some [_1] were not restored because their parent objects were not restored.', 'MT::FileInfo' ) );
    }

    1;
}

1;
