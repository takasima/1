<?php
function smarty_block_mtifaltsearchmodeiscategories ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $categories = $app->param( 'categories' );
    $category   = $app->param( 'category' );
    if ( $categories ) {
        if (! is_array( $categories ) ) {
            $categories = preg_split( '/\s*,\s*/', $categories, -1, PREG_SPLIT_NO_EMPTY );
        }
    } else {
        $categories = array();
    }
    if ( $category ) {
        $categories[] = $category;
    }
    if ( $categories && preg_grep( "/^\d+$/", $categories ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>