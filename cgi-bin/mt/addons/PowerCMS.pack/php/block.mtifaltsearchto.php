<?php
function smarty_block_mtifaltsearchto ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $to = $app->param( 'to' );
    if ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $to ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>