<?php
function smarty_block_mtiftablet( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $cond = $app->get_agent( 'Tablet' );
    $cond = $cond == 1 ? TRUE : FALSE;
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $cond );
}