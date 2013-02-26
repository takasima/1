<?php
function smarty_block_mtifbrokenrss ( $args, $content, $ctx, $repeat ) {
    if (! isset( $content ) ) {
        $link = $ctx->stash( 'link' );
        if (! isset( $link ) ) {
            return $ctx->error();
        } else {
            $brokenrss = $link->broken_rss;
            if ( $brokenrss == 1 ) {
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