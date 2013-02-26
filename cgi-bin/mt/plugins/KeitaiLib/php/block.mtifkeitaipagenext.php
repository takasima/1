<?php
function smarty_block_mtifkeitaipagenext( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $page    = $ctx->stash( "_keitai_current" );
        $counter = $ctx->stash( "_keitai_page_count" );
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $page < $counter );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>