<?php
function smarty_block_mtifsmartphone( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $exclude = $args[ 'exclude' ];
    if ( $exclude ) {
        $exclude = strtolower( $exclude );
        if ( $exclude == 'tablet' ) {
            if ( $app->get_agent( 'Smartphone', NULL, $exclude ) ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
            } else {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
            }
        }
    }
    $cond = $app->get_agent( 'Smartphone' );
    $cond = $cond == 1 ? TRUE : FALSE;
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $cond );
}