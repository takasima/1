<?php
function smarty_block_mtifaltsearchmetadatasfooter ( $args, $content, $ctx, $repeat ) {
    $counter = $ctx->stash( '_altsearch_counter' );
    $pages = $ctx->stash( 'pages' );
    if ( $counter ) {
        if ( $counter == $pages ) {
            return $ctx->_hdlr_if($args, $content, $ctx, $repeat, 1);
        } else {
            return $ctx->_hdlr_if($args, $content, $ctx, $repeat, 0);
        }
    } else {
        return $ctx->error( "No _altsearch_counter available" );
    }
}
?>