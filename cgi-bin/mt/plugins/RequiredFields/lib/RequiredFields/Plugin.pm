package RequiredFields::Plugin;

use strict;
use warnings;

our $plugin_requiredfields = MT->component( 'RequiredFields' );

# チェック用スクリプトの埋め込み
sub _append_scripts {
    my ( $cb, $app, $ref_str ) = @_;

    return unless $app->blog;

    my $blog_id = $app->blog->id;
    my $preview_check = $plugin_requiredfields->get_config_value(
        'preview_check',
        'blog:' . $blog_id );

    #my $t = time;

    # $('#entry_form').submit(fn) は2度目以降呼ばれなかったので
    my $html = <<'HTML';
<script type="text/javascript" charset="utf-8" src="<$MTStaticWebPath$>plugins/RequiredFields/js/validator.js?<$MTDate format="%Y%m%d%H%M%S"$>"></script>
<script type="text/javascript" charset="utf-8" src="<$MTStaticWebPath$>plugins/RequiredFields/js/check-fields.js?<$MTDate format="%Y%m%d%H%M%S"$>"></script>
<mt:setVarBlock name="jq_js_include" append="1">
jQuery(function($) {
    $('input[type="submit"].action, button[type="submit"].action')
HTML
    my $jq_selector = '.publish';
    if ($preview_check) {
        $jq_selector .= ', .preview';
    }
    $html .= <<HTML;
        .filter("$jq_selector")
HTML
    $html .= <<'HTML';
            .bind("click", function fieldValidation() {
                app.saveHTML(false);
                var ret = $('#entry_form').checkFields({
                    standard_fields: <$MTVar name="standard_fields" to_json="1"$>,
                    ext_fields: <$MTVar name="ext_fields" to_json="1"$>,
                    category_equired: <$MTVar name="category_equired" to_json="1"$>
                });
                return ret;
            });
});
</mt:setVarBlock>
HTML

    $$ref_str =~ s|(<mt:include name="include/footer.tmpl")|$html$1|;
}

# チェックパラメータの埋め込み準備
sub _append_params {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return unless $app->blog;
    my $blog_id = $app->blog->id;

    my $standard_fields_val = $plugin_requiredfields->get_config_value(
        'standard_fields',
        'blog:' . $blog_id );
    my $ext_fields_val = $plugin_requiredfields->get_config_value(
        'ext_fields',
        'blog:' . $blog_id );
    my $category_required_val = $plugin_requiredfields->get_config_value(
        'category_equired',
        'blog:' . $blog_id );

    $standard_fields_val =~ s/\r\n?/\n/g;
    $ext_fields_val =~ s/\r\n?/\n/g;

    my %standard_fields = map { my ( $key, $val ) = split /\s*,\s*/; } ( split /\n\s*/, $standard_fields_val );
    #my @standard_fields = split( /\n\s*/, $standard_fields_val );
    my @ext_fields = split( /\n\s*/, $ext_fields_val );

    $param->{standard_fields}  = \%standard_fields;
    $param->{ext_fields}       = \@ext_fields;
    $param->{category_equired} = $category_required_val ? 'true' : 'false';
}

sub log_debug {
    my ( $msg ) = @_;
    return unless defined ( $msg );

    require MT::Log;
    my $log = MT->log({
        level => MT::Log::DEBUG(),
        message => $msg
    });
}

1;
