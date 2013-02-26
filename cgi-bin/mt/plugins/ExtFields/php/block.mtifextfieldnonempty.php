<?php
function smarty_block_mtifextfieldnonempty ( $args, $content, $ctx, $repeat ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if (! isset( $extfield ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
    $text = $extfield->extfields_text;
    if ( $text ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>