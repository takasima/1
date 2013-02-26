<?php
function smarty_block_mtifformelementvalidate ( $args, $content, &$ctx, &$repeat ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( isset( $contactform ) && $contactform->validate ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
    }
}
?>