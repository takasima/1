<?php
function smarty_block_mtifaltsearchresultprev ( $args, $content, $ctx, $repeat ) {
    $prev = $ctx->stash( 'prev' );
    if ( $prev ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>