<?php
function smarty_block_mtifaltsearchsort_order ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $sort_order = $app->param( 'sort_order' );
    if ( ( $sort_order == 'ascend' ) || ( $sort_order == 'descend' ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>