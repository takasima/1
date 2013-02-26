<?php
function smarty_block_mtifkeitai( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $cond = $app->get_agent( 'Keitai' );
    $cond = $cond == 1 ? TRUE : FALSE;
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $cond );
}
?>