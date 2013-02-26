<?php
function smarty_block_mtifplugin( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $component = $args[ 'component' ] ? $args[ 'component' ] : $args[ 'plugin' ];
    if ( $component ) {
        if ( $app->component( $component ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
}
?>