<?php
function smarty_block_mtifextfield ( $args, $content, &$ctx, $repeat ) {
    $label = $args[ 'label' ];
    if ( $label ) {
        require_once ( 'extfield.util.php' );
        $extfield  = get_extfield( $args, $ctx );
        if ( isset ( $extfield ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }
    } else {
        $entry = $ctx->stash( 'entry' );
        if ( $entry ) {
            $entry_id = $entry->entry_id;
        } else {
            return $ctx->error( "No entry available" );
        }
        require_once "class.mt_extfields.php";
        $_ext = new ExtFields;
        $where = "extfields_entry_id = {$entry_id} "
               . " AND  extfields_status = 1 ";
        $results = $_ext->Find( $where );
        if ( count( $results ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>