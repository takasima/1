<?php
function smarty_block_mtifextFieldfileexists ( $args, $content, &$ctx, $repeat ) {
    require_once ( 'function.mtblogsitepath.php' );
    $app = $ctx->stash( 'bootstrapper' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( $extfield ) {
        $blog = $ctx->stash( 'blog' );
        $buf = array(
            'id' => $blog->blog_id
        );
        $blog_path = smarty_function_mtblogsitepath( $buf, $ctx );
        $blog_path = $app->chomp_dir( $blog_path );
        $filepath = $extfield->extfields_text;
        $filepath = str_replace ( '%r', $blog_path, $filepath );
        if ( DIRECTORY_SEPARATOR != '/' ) {
            $filepath = str_replace( '/', DIRECTORY_SEPARATOR, $filepath );
        }
        if ( file_exists( $filepath ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>