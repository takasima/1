<?php
function smarty_block_mtifaltsearchmetadatasheader ( $args, $content, $ctx, $repeat ) {
    $counter = $ctx->stash( '_altsearch_counter' );
    if ( $counter ) {
        if ( $counter == 1 ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }
    } else {
        return $ctx->error( "No _altsearch_counter available" );
    }
}
?>