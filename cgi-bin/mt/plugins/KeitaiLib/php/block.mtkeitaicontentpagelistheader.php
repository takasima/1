<?php
function smarty_block_mtkeitaicontentpagelistheader( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $ctx->stash( "_list_counter" ) == 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>