<?php
function smarty_block_mtlinksheader ( $args, $content, $ctx, $repeat ) {
    if (! isset( $content ) ) {
        $vars =& $ctx->__stash[ 'vars' ];
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $vars[ '__first__' ] == 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>