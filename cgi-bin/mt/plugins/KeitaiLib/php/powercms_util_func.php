<?php
function powercms_util_request_uri_rel2abs ( $rel_path='', $request_uri_dir='' ) {
    if (! $request_uri_dir ) {
        $request_uri_dir = powercms_util_request_uri_base();
    }
    return powercms_util_resolveuri ( $request_uri_dir . $rel_path );
}

function powercms_util_resolveuri ( $path='/' ) {
    if (! preg_match( '/^\//',$path ) ) {
        return $path; // path is not abs path
    }
    $path = powercms_util_canonpath( $path );
    $rel = explode( '/', $path );
    $abs = array();
    foreach ( $rel as $dir_name ) {
        if ( $dir_name == '..' ) {
            if ( count( $abs ) > 1 ) {
                array_pop( $abs );
            }
        } else {
            array_push( $abs, $dir_name );
        }
    }
    return implode( '/', $abs );
}

function powercms_util_canonpath ( $path = '' ) {
    $path = preg_replace( '/\/{2,}/', '/', $path );             // xx////xx -> xx/xx
    $path = preg_replace( '/(?:\/\.)+(?:\/|\z)/', '/', $path ); // xx/././xx -> xx/xx
    if ( $path != './' ) {
        $path = preg_replace( '/^(?:\.\/)+/s', '', $path );     // ./xx -> xx
    }
    $path = preg_replace( '/^\/(?:\.\.\/)+/', '/', $path );     // /../../xx -> xx
    $path = preg_replace( '/^\/\.\.$/', '/', $path );           // /.. -> /
    if ( $path != '/' ) {
        $path = preg_replace( '/\/\z/', '', $path );            // xx/ -> xx
    }
    return $path;
}

function powercms_util_request_uri_base ( $uri = '' ) {
    $parsed = powercms_util_parse_this_uri( $uri );
    if (! $parsed ) {
        return '/';
    }
    return preg_replace( '/[^\/]*$/', '', $parsed[ 'path' ] );
}

function powercms_util_parse_this_uri ( $uri = '' ) {
    if (! $uri ) {
        $uri = powercms_util_get_this_uri();
    }
    return parse_url( $uri );
}

function powercms_util_get_this_uri ( $base = '' ) {
    if (! $base ) {
        $base = powercms_util_get_base_url();
    }
    if ( !preg_match( '/\/$/', $base ) ) {
        $base .= '/';
    }
    $request_uri = $_SERVER[ 'REQUEST_URI' ];
    return sprintf( '%s%s',rtrim( $base, '/' ),$request_uri );
}

function powercms_util_get_base_url () {
    $hostname = $_SERVER[ 'HTTP_HOST' ];
    $is_secure = 0;
    if ( $_SERVER[ 'HTTPS' ] == 'ON' ) {
        $is_secure = 1;
    }
    $port = $_SERVER[ 'SERVER_PORT' ];
    if ( $port == 443 ) {
        $is_secure = 1;
    }
    $port_str = '';
    if ( $is_secure ) {
        $scheme = 'https';
        if ( $port && $port != 443 ) $port_str = ':'.$port;
    }
    else {
        $scheme = 'http';
        if ( $port && $port != 80 ) $port_str = ':'.$port;
    }
    return sprintf( '%s://%s%s/', $scheme, $hostname, $port_str );
}
?>