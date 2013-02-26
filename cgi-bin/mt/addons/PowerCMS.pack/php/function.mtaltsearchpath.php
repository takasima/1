<?php
function smarty_function_mtaltsearchpath ( $args, $ctx ) {
    $blog_id = $ctx->stash( 'blog_id' );
    $blog_id = intval( $blog_id );
    if ( $blog_id ) {
        $blog = $ctx->stash( 'blog' );
        $meta = $blog->powercms_config;
        $meta = preg_replace( "/^.*(SERG)/", '$1', $meta );
        $config = $ctx->mt->db()->unserialize( $meta );
        $setting = $config[ 'powercms' ];
        $searchpath = isset( $setting[ 'altsearch_path' ] ) ? $setting[ 'altsearch_path' ] : 'dynamic/search.html';
    } else {
        $searchpath = 'dynamic/search.html';
    }
    return $searchpath;
}
?>