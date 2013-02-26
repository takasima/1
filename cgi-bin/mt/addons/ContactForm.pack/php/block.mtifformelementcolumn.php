<?php
function smarty_block_mtifformelementcolumn ( $args, $content, &$ctx, &$repeat ) {
    $contactform = $ctx->stash( 'contactform' );
    $column = $args[ column ];
    if ( isset( $contactform ) ) {
        if (! $contactform->has_column( $column ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
        }
    }
    if ( isset( $contactform ) && $contactform->$column ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
    }
}
?>