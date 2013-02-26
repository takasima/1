<?php
function smarty_block_mtifaltsearchand_or ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $and_or = $app->param( 'and_or' );
    if ( ( $and_or == 'and' ) || ( $and_or == 'or' ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>