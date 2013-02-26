<?php
require_once('function.mtblogurl.php');
function smarty_function_mtmembersloginurl ( $args, &$ctx ) {
    $memberscript = $ctx->mt->config( 'MemberScript' );

    if ( !$memberscript ) {
        $cgi_path = $ctx->mt->config( 'CGIPath' );

        if ( substr( $path, 0, 1 ) == '/' ) {  # relative
            $blog = $ctx->stash( 'blog' );
            $buf = array(
                'id' => $blog->blog_id
            );

            $host = smarty_function_mtblogurl($buf, $ctx);

            if ( !preg_match( '!/$!', $host ) ) {
                $host .= '/';
            }
            if ( preg_match( '!^(https?://[^/:]+)(:\d+)?/!', $host, $matches ) ) {
                $cgi_path = $matches[ 1 ] . $cgi_path;
            }
        }
        if ( substr( $cgi_path, strlen( $cgi_path ) - 1, 1 ) != '/' ) {
            $cgi_path .= '/';
        }
        $memberscript = $cgi_path . 'mt-members.cgi';
    }
    $blog = $ctx->stash( 'blog' );
    $buf = array(
        'id' => $blog->blog_id
    );

    $blog_url = smarty_function_mtblogurl($buf, $ctx);
    $return_url = $args[ 'return_url' ] || $blog_url;
    return $memberscript . '?__mode=start_login&amp;return_url=' . urlencode( $return_url ) . '&amp;blog_id=' . $blog->blog_id;
}
?>
