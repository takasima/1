<?php
require_once 'powercms_util_func.php';
function smarty_modifier_add_session_for_mobile( $text, $args ) {
    if ( !$args ) {
        return $text;
    }
    $sessid = $_REQUEST['sessid'];
    if ( !isset( $sessid ) ) {
        return $text;
    }
    $mt   = MT::get_instance();
    $ctx  =& $mt->context();
    $blog = $ctx->stash( 'blog' );

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
        return $text; // error
    }

    $reg_url  = preg_quote( $site_url, '/' );
    $reg_path = preg_quote( $path, '/' );

    $regex = '/(<\s*(a|img)\s[^>]*?(href|src)\s*=\s*")'
           . '([^"]*?)(".*?>)/is';
    $regfunc =
        '$begin = $m[1]; $query = $m[4]; $end = $m[5];'
    .   '$tag_name = $m[2]; $attr_name = $m[3];'
    .   'if ( !('
    .        ' ( $tag_name == "a" && $attr_name == "href" )'
    .     ' || ( $tag_name == "img" && $attr_name == "src" )'
    .     ' ) ) {'
    .       'return $m[0];' // Not applicable
    .   '} '
    .   'if ( preg_match( \'/^http/\',$query ) ) {'
    .       'if ( !preg_match( \'/^' . $reg_url . '/\',$query ) ) {'
    .           'return $m[0];' // Not applicable
    .       '} '
    .   '} '
    .   'else if ( preg_match( \'/^\//\',$query ) ) {'
    .       'if ( !preg_match( \'/^' . $reg_path . '/\',$query ) ) {'
    .           'return $m[0];' // Not applicable
    .       '} '
    .   '} '
    .   'else {' // Relative path
    .       '$abspath = powercms_util_request_uri_rel2abs( $query );'
    .       'if ( !preg_match( \'/^' . $reg_path . '/\',$abspath ) ) {'
    .           'return $m[0];' // Not applicable
    .       '} '
    .   '} '
    .   '$query = preg_replace( \'/([?&;])sessid=[^&;]*([&;]?)/\', \'$1\', $query );'
    .   '$query = preg_replace( \'/([?&;])$/\', "", $query );'
    .   'if (preg_match( \'/\?/\',$query )) {'
    .       'return $begin.$query.\'&sessid=' . $sessid . '\'.$end;'
    .   '} '
    .   'else {'
    .       'return $begin.$query.\'?sessid=' . $sessid . '\'.$end;'
    .   '}';

    return preg_replace_callback(
        $regex,
        create_function('$m', $regfunc),
        $text
    );
}
?>
