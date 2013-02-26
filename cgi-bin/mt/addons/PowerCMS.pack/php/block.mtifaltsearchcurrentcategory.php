<?php
function smarty_block_mtifaltsearchcurrentcategory ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $cat = $ctx->stash( 'category' );
    $category = $app->param( 'category' );
    if ( $cat->category_id == $category ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>