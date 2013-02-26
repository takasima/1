<?php
function smarty_block_mtifkeitaipageprev( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $page    = $ctx->stash( "_keitai_current" );
        $counter = $ctx->stash( "_keitai_page_count" );
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $page > 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>