<?php
function smarty_block_mtifextfieldtype ( $args, $content, &$ctx, $repeat ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    $match_type = $args[ 'type' ];
    if (! isset ( $extfield ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
    $type = $extfield->extfields_type;
    if ( $type ) {
        if ( $match_type == $type ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>