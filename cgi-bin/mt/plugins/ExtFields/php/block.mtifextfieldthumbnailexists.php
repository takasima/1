<?php
function smarty_block_mtifextfieldthumbnailexists ( $args, $content, &$ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    require_once ( 'function.mtblogsitepath.php' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $blog = $ctx->stash( 'blog' );
        $buf = array(
            'id' => $blog->blog_id
        );
        $blog_path = smarty_function_mtblogsitepath( $buf, $ctx );
        $blog_path = $app->chomp_dir( $blog_path );
        $filepath = $extfield->extfields_thumbnail;
        if ( DIRECTORY_SEPARATOR != '/' ) {
            $filepath = str_replace( '/', DIRECTORY_SEPARATOR, $filepath );
        }
        $filepath = str_replace ( '%r', $blog_path, $filepath );
        if ( file_exists( $filepath ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>