<?php
function smarty_block_mtifaltsearchmodeiscategory ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $category = $app->param( 'category' );
    if ( ( $category != '' ) && preg_match( "/^[0-9]+$/", $category ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>