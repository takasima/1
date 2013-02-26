<?php
function smarty_block_mtifaltsearchfrom ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $from = $app->param( 'from' );
    if ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $from ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>