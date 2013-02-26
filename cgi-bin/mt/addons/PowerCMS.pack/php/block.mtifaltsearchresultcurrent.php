<?php
function smarty_block_mtifaltsearchresultcurrent ( $args, $content, $ctx, $repeat ) {
    $counter = $ctx->stash( '_altsearch_counter' );
    $current = $ctx->stash( 'current' );
    if ( $counter ) {
        if ( $counter == $current ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }        
    } else {
        return $ctx->error( "No _altsearch_counter available" );
    }
}
?>