<?php
function smarty_block_mtifkeitaipagecurrent( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $page    = $ctx->stash( "_keitai_current" );
        $current = $ctx->stash( "_list_counter" );
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $page == $current );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>