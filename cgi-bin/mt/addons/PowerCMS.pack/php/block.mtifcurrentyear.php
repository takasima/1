<?php
function smarty_block_mtifcurrentyear ( $args, $content, $ctx, $repeat ) {
    $currentyear = $ctx->stash( 'currentyear' );
    if ( $currentyear > 0 ) {
        if ( $currentyear == 2 ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>