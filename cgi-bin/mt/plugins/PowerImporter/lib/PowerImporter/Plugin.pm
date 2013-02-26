package PowerImporter::Plugin;
use strict;

use MT::Util qw( encode_html );

sub _start_import {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerImporter' );
    my $scope = 'blog:'. $app->blog->id;
    my $html_title_field = $plugin->get_config_value( 'html_title_field', $scope ) || '';
    my $html_text_field  = $plugin->get_config_value( 'html_text_field', $scope ) || '';
    my $html_more_field  = $plugin->get_config_value( 'html_more_field', $scope ) || '';
    my $html_expt_field  = $plugin->get_config_value( 'html_expt_field', $scope ) || '';
    my $html_kywd_field  = $plugin->get_config_value( 'html_kywd_field', $scope ) || '';
    my $html_extensions  = $plugin->get_config_value( 'html_extensions', $scope ) || '';
    my $start_end_separator  = $plugin->get_config_value( 'start_end_separator', $scope ) || ',';
    my $html_overwrite   = $plugin->get_config_value( 'html_overwrite', $scope ) || 0;
    my $html_import_root = $plugin->get_config_value( 'html_import_root', $scope ) || '';
    my $html_exclude_root = $plugin->get_config_value( 'html_exclude_root', $scope ) || '';
    my $html_do_realtime = $plugin->get_config_value( 'html_do_realtime', $scope ) || '';
    my $html_save_settings = $plugin->get_config_value( 'html_save_settings', $scope ) || 0;
    my $create_folder = $plugin->get_config_value( 'create_folder', $scope ) || 0;
    my $all_cats  = $plugin->get_config_value( 'all_cats',  $scope ) || 0;
    my $entry_class  = $plugin->get_config_value( 'entry_class',  $scope ) || 'page';
    my $title_regex = $plugin->get_config_value( 'title_regex', $scope ) || 0;
    my $text_regex  = $plugin->get_config_value( 'text_regex', $scope ) || 0;
    my $more_regex  = $plugin->get_config_value( 'more_regex', $scope ) || 0;
    my $expt_regex  = $plugin->get_config_value( 'expt_regex', $scope ) || 0;
    my $kywd_regex  = $plugin->get_config_value( 'kywd_regex', $scope ) || 0;
    $html_title_field = encode_html( $html_title_field );
    $html_text_field  = encode_html( $html_text_field );
    $html_more_field  = encode_html( $html_more_field );
    $html_expt_field  = encode_html( $html_expt_field );
    $html_kywd_field  = encode_html( $html_kywd_field );
    $html_extensions  = encode_html( $html_extensions );
    $html_import_root = encode_html( $html_import_root );
    $html_exclude_root = encode_html( $html_exclude_root );
    $start_end_separator = encode_html( $start_end_separator );
    my $field; my $out;
    $field = '<input type="text" id="html_title_field" name="html_title_field" class="full-width" value="" />';
    $out   = '<input type="text" id="html_title_field" name="html_title_field" class="full-width" value="' . $html_title_field . '" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" id="html_text_field" name="html_text_field" class="full-width" value="" />';
    $out   = '<input type="text" id="html_text_field" name="html_text_field" class="full-width" value="' . $html_text_field . '" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" id="html_more_field" name="html_more_field" class="full-width" value="" />';
    $out   = '<input type="text" id="html_more_field" name="html_more_field" class="full-width" value="' . $html_more_field . '" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" id="html_expt_field" name="html_expt_field" class="full-width" value="" />';
    $out   = '<input type="text" id="html_expt_field" name="html_expt_field" class="full-width" value="' . $html_expt_field . '" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" id="html_kywd_field" name="html_kywd_field" class="full-width" value="" />';
    $out   = '<input type="text" id="html_kywd_field" name="html_kywd_field" class="full-width" value="' . $html_kywd_field . '" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" name="html_extensions" value="" style="width:200px" />';
    $out   = '<input type="text" name="html_extensions" value="' . $html_extensions . '" style="width:200px" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" name="start_end_separator" value="" style="width:200px" />';
    $out   = '<input type="text" name="start_end_separator" value="' . $start_end_separator . '" style="width:200px" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="radio" name="entry_class" value="' . $entry_class . '" />';
    $out = '<input type="radio" name="entry_class" value="' . $entry_class . '" checked="checked" />';
    $$tmpl =~ s/$field/$out/;
    if ( $html_overwrite ) {
        $field = '<input type="checkbox" name="html_overwrite" value="1" />';
        $out = '<input type="checkbox" name="html_overwrite" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    $field = '<input type="text" name="html_import_root" class="full-width" value="" />';
    $out   = '<input type="text" name="html_import_root" class="full-width" value="' . $html_import_root . '" />';
    $$tmpl =~ s/$field/$out/;
    $field = '<input type="text" name="html_exclude_root" class="full-width" value="" />';
    $out   = '<input type="text" name="html_exclude_root" class="full-width" value="' . $html_exclude_root . '" />';
    $$tmpl =~ s/$field/$out/;
    if ( $html_do_realtime ) {
        $field = '<input type="checkbox" id="html_do_realtime" name="html_do_realtime" value="1" />';
        $out = '<input type="checkbox" id="html_do_realtime" name="html_do_realtime" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $create_folder ) {
        $field = '<input type="checkbox" id="create_folder" name="create_folder" value="1" />';
        $out = '<input type="checkbox" id="create_folder" name="create_folder" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $all_cats ) {
        $field = '<input type="checkbox" id="all_cats" name="all_cats" value="1" />';
        $out = '<input type="checkbox" id="all_cats" name="all_cats" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $html_save_settings ) {
        $field = '<input type="checkbox" id="html_save_settings" name="html_save_settings" value="1" />';
        $out = '<input type="checkbox" id="html_save_settings" name="html_save_settings" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $title_regex ) {
        $field = '<input type="checkbox" name="title_regex" value="1" />';
        $out = '<input type="checkbox" name="title_regex" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $text_regex ) {
        $field = '<input type="checkbox" name="text_regex" value="1" />';
        $out = '<input type="checkbox" name="text_regex" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $more_regex ) {
        $field = '<input type="checkbox" name="more_regex" value="1" />';
        $out = '<input type="checkbox" name="more_regex" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $expt_regex ) {
        $field = '<input type="checkbox" name="expt_regex" value="1" />';
        $out = '<input type="checkbox" name="expt_regex" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
    if ( $kywd_regex ) {
        $field = '<input type="checkbox" name="kywd_regex" value="1" />';
        $out = '<input type="checkbox" name="kywd_regex" value="1" checked="checked" />';
        $$tmpl =~ s/$field/$out/;
    }
}

sub _import_end {
    my ( $cb, $app, $tmpl ) = @_;
    if ( $app->param( 'import_type' ) eq 'import_html' ) {
        $$tmpl =~ s/<mt:unless\sname="import_upload">.*?<\/mt:unless>//is;
    }
}

1;