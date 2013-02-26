package KeitaiLib::Patch;
use strict;

sub init {
    # Only for override.
    # Do nothing.
}

package MT::App;
use PowerCMS::Util qw( is_ua_keitai );
no warnings 'redefine';

my $_bake_cookie = *bake_cookie{CODE};
*bake_cookie = sub {
    if ( MT->config->NoCookieHeaderToKeitai && is_ua_keitai() ) {
        return;
    }
    return $_bake_cookie->( @_ );
};

my $_set_header = *set_header{CODE};
*set_header = sub {
    my ( $app, $key, $val ) = @_;
    if ( MT->config->NoCookieHeaderToKeitai && $key eq '-cookie' && is_ua_keitai() ) {
        return;
    }
    return $_set_header->( @_ );
};

1;