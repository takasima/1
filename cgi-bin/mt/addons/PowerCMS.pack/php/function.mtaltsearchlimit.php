<?php
function smarty_function_mtaltsearchlimit ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $limit = $app->param( 'limit' );
    if ( $limit == '' || ! ctype_digit( $limit ) ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog_id = intval( $blog_id );
        if ( $blog_id ) {
            $blog = $ctx->stash( 'blog' );
            $meta = $blog->powercms_config;
            $meta = preg_replace( "/^.*(SERG)/", '$1', $meta );
            $meta = $ctx->mt->db()->unserialize( $meta );
            $meta = $meta[ 'powercms' ];
            $limit = $meta[ 'altsearch_default_limit' ];
            $limit = intval( $limit );
        } else {
            $limit = 20;
        }
        if (! $limit ) {
            $limit = 20;
        }
    }
    return htmlspecialchars( $limit );
}
?>