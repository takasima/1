<?php
function smarty_block_mtkeitaicontentpagelistfooter( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $ctx->stash( "_list_counter" ) == $ctx->stash( "_keitai_page_count" ) );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>