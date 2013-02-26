package ViewSite::Plugin;

use strict;

sub _cfg_system_general {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerCMS' );
    my $pointer_field = $tmpl->getElementById( 'system_debug_mode' );
    my $nodeset = $tmpl->createElement( 'app:setting', { id => 'use_minifier',
                                                         label => $plugin->translate( 'Default WebSite URL' ) ,
                                                         show_label => 1,
                                                         content_class => 'field-content-text' } );
    my $innerHTML = <<MTML;
<__trans_section component="PowerCMS">
        <input type="text" id="default_website_url" name="default_website_url" value="<mt:var name="default_website_url">" />
</__trans_section>
MTML
    $nodeset->innerHTML( $innerHTML );
    $tmpl->insertBefore( $nodeset, $pointer_field );
    $param->{ default_website_url } = MT->config( 'DefaultWebSiteURL' );
    return 1;
}

1;