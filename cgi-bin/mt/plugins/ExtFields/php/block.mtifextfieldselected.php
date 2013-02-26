<?php
function smarty_block_mtifextfieldselected ( $args, $content, $ctx, $repeat ) {
    $selected = $ctx->stash( 'selected' );
    if ( $selected ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>