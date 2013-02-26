package PowerCMS::Widgets;
use strict;

sub _powercms_news_widget {
    my $app = shift;
    my ( $tmpl, $param ) = @_;
    $param->{ news_html } = get_newsbox_content( $app ) || '';
}

sub get_newsbox_content {
    my $app = MT->instance;
    my $newsbox_url = $app->config( 'PowerCMSNewsURL' ) || 'http://alfasado.net/powercmsnews.html';
    if ( $newsbox_url && $newsbox_url ne 'disable' ) {
        return MT::Util::get_newsbox_html( $newsbox_url, 'PN' );
    }
    return q();
}

1;