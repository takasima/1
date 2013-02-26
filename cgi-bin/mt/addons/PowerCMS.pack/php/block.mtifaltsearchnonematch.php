<?php
function smarty_block_mtifaltsearchnonematch ( $args, $content, $ctx, $repeat ) {
    $match = $ctx->stash( 'match' );
    if ( $match == 0 ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>