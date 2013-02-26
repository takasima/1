<?php
function smarty_block_mtifaltsearchcurrentcategories ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $cat = $ctx->stash( 'category' );
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
    if ( $categories && preg_grep( "/^\d+$/", $categories ) && in_array( $cat->category_id, $categories ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>