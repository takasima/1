<?php
function smarty_block_mtifformelementrequired ( $args, $content, &$ctx, &$repeat ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( isset( $contactform ) && $contactform->required ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
    }
}
?>