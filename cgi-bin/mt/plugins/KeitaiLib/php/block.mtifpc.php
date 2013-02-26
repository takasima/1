<?php
function smarty_block_mtifpc( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $agent = $app->get_agent();
    $cond = $agent == 'PC' ? TRUE : FALSE;
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $cond );
}