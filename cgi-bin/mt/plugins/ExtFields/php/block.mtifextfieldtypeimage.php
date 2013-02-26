<?php
function smarty_block_mtifextfieldtypeimage ( $args, $content, &$ctx, &$repeat ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if (! isset ( $extfield ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
    $type = $extfield->extfields_file_type;
    if ( $type ) {
        if ( $type == 'image' ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>