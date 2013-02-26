<?php
function smarty_block_mtifbrokenlink ( $args, $content, $ctx, $repeat ) {
    if (! isset( $content ) ) {
        $link = $ctx->stash( 'link' );
        if (! isset( $link ) ) {
            return $ctx->error();
        } else {
            $brokenlink = $link->broken_link;
            if ( $brokenlink == 1 ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, true );
            } else {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, false );
            }
        }
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>