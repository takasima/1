<?php
function smarty_block_mtifaltsearchquery ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $query = $app->param( 'query' );
    $query = preg_replace( '/\s{2,}/', ' ', $query );
    $query = preg_replace( '/^\s/', '', $query );
    $query = preg_replace( '/\s$/', '', $query );
    if ( $query != '' ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>