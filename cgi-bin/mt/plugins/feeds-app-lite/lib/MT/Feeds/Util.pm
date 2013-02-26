package MT::Feeds::Util;

use strict;
use base 'Exporter';

use MT::I18N qw( encode_text utf8_off );
use Encode;

our @EXPORT_OK = qw( decode_data );

sub decode_data {
    my ($data) = @_;
    return '' unless $data;

    my $enc = MT->config->PublishCharset;
    if ( $enc =~ m/^utf-?8$/i ) {
        if ( Encode::is_utf8($data) ) {
            $data = MT::I18N::utf8_off($data);
            $data = MT::I18N::decode_utf8($data);
        }
    }
    else {
        $data = encode_text( $data, undef, 'utf-8' );
    }

    return $data;
}

1;
