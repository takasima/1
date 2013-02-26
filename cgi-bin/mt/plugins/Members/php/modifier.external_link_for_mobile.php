<?php
require_once('powercms_util_func.php');
function smarty_modifier_external_link_for_mobile( $text, $args ) {
    if ( !$args ) {
        return $text;
    }
    $mt   = MT::get_instance();
    $ctx  =& $mt->context();
    $blog = $ctx->stash( 'blog' );
    if ( !$blog ) {
        return $text;
    }
    $cgipath = $mt->config('CGIPath');
    $blog_id = $mt->blog_id();

    // site_url must begin with http and end with /
    $site_url = $blog->site_url();
    if ( preg_match( '/^http/', $args ) ) {
        $site_url = $args;
    }
    if ( !preg_match ( '/\/$/', $site_url ) ) {
        $site_url .= '/';
    }
    if ( preg_match( '/^(https?:\/\/.*?)(\/.*)$/', $site_url, $url ) ) {
        $path = $url[2];
    }
    else {
        return $text; //error
    }

    $reg_url  = preg_quote( $site_url, '/' );
    $reg_path = preg_quote( $path, '/' );

    $regex = '/(<\s*a\s[^>]*?href\s*=\s*")'
           . '([^"]*?)(".*?>)/is';
    $regfunc =
        '$begin = $m[1]; $query = $m[2]; $end = $m[3];'
    .   'if ( preg_match( \'/^http/\',$query ) ) {'
    .       'if ( preg_match( \'/^' . $reg_url . '/\',$query ) ) {'
    .           'return $m[0];' // Not Applicable
    .       '} '
    .   '} '
    .   'else if ( preg_match( \'/^\//\',$query ) ) {'
    .       'if ( preg_match( \'/^' . $reg_path . '/\',$query ) ) {'
    .           'return $m[0];' // Not Applicable
    .       '} '
    .   '} '
    .   'else {' // relative path
    .       '$abspath = powercms_util_request_uri_rel2abs( $query );'
    .       'if ( preg_match( \'/^' . $reg_path . '/\',$abspath ) ) {'
    .           'return $m[0];' // Not Applicable
    .       '} '
    .       'if (preg_match( \'/\?/\',$query )) {'
    .           '$query = preg_replace( \'/^.*?\?$/\', "$abspath?", $query );'
    .       '} '
    .       'else {'
    .           '$query = $abspath;'
    .       '} '
    .   '} '
    .   '$query = urlencode( $query );'
    .   '$rurl = \''.$cgipath.'mt-members.cgi?__mode=redirect&blog_id='.$blog_id.'\';'
    .   '$rurl .= \'&url=\' . $query;'
    .   'return $begin.$rurl.$end;';

    return preg_replace_callback(
        $regex,
        create_function(
            '$m',
            $regfunc
        ),
        $text
    );
}

