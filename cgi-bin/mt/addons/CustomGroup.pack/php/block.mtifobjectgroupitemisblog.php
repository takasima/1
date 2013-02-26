<?php
function smarty_block_mtifobjectgroupitemisblog( $args, $content, $ctx, $repeat ) {
    $object_ds = $ctx->stash( 'object_ds' );
    if ( $object_ds == 'blog' ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>