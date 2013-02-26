<?php
function smarty_block_mtifaltsearchresultnext ( $args, $content, $ctx, $repeat ) {
    $next = $ctx->stash( 'next' );
    if ( $next ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>