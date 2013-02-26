<?php
function smarty_block_mtifaltsearchcategories_and_or ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $categories_and_or = $app->param( 'categories_and_or' );
    if ( ( $categories_and_or == 'and' ) || ( $categories_and_or == 'or' ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>