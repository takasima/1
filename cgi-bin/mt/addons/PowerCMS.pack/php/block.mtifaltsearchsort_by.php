<?php
function smarty_block_mtifaltsearchsort_by ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $sort_by = $app->param( 'sort_by' );
    if ( ( $sort_by == 'id' ) ||
         ( $sort_by == 'title' ) ||
         ( $sort_by == 'modified_on' ) ||
         ( $sort_by == 'text' ) ||
         ( $sort_by == 'text_more' ) ||
         ( $sort_by == 'keywords' ) ||
         ( $sort_by == 'excerpt' ) ||
         ( $sort_by == 'author_id' ) ||
         ( $sort_by == 'authored_on' ) ||
         ( $sort_by == 'created_on' ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>