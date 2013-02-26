<?php
function smarty_block_mtifaltsearchmatchquery ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $query = $app->param( 'query' );
    if ( $query ) {
        $value = $args[ 'value' ];
        $query = preg_replace( '/^\s/', '', $query );
        $query = preg_replace( '/\s$/', '', $query );
        if ( $tag ) {
            $query = preg_replace( '/,\s{2,}/', ',', $query );
            $qs = explode( ',', $query );
            foreach ( $qs as $q ) {
                if ( preg_match( "/$value/i", $q ) ) {
                    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
                }
            }
        } else {
            $query = preg_replace ( '/\s{2,}/', ' ', $query );
            $qs = explode( ' ', $query );
            foreach ( $qs as $q ) {
                if ( preg_match( "/$value/i", $q ) ) {
                    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
                }
            }
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>