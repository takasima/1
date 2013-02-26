<?php
function smarty_block_mtifipad( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $agent = $app->get_agent();
    $cond = $agent == 'iPad' ? TRUE : FALSE;
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $cond );
}
?>