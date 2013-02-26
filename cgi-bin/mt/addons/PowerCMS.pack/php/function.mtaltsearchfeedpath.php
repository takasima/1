<?php
function smarty_function_mtaltsearchfeedpath ( $args, $ctx ) {
    $blog_id = $ctx->stash( 'blog_id' );
    $blog_id = intval( $blog_id );
    if ( $blog_id ) {
        $blog = $ctx->stash( 'blog' );
        $meta = $blog->powercms_config;
        $meta = preg_replace( "/^.*(SERG)/", '$1', $meta );
        $config = $ctx->mt->db()->unserialize( $meta );
        $setting = $config[ 'powercms' ];
        $feedpath = isset( $setting[ 'altsearch_feedpath' ] ) ? $setting[ 'altsearch_feedpath' ] : 'dynamic/feed.xml';
    } else {
        $feedpath = 'dynamic/feed.xml';
    }
    return $feedpath;
}
?>