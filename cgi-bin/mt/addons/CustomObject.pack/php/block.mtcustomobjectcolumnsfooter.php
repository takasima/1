<?php
function smarty_block_mtcustomobjectcolumnsfooter ( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $vars =& $ctx->__stash[ 'vars' ];
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $vars[ '__last__' ] == 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>