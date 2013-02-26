<?php
function smarty_block_mtkeitaicontentpagelist( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( "_list_counter" );
    if (! isset( $content ) ) {
        $counter = 0;
        $ctx->stash( "_list_counter", $counter );
    } else {
        $counter = $ctx->stash( "_list_counter" );
    }
    $pages = $ctx->stash( "_keitai_page_count" );
    if  ( $pages > $counter ) {
        $ctx->stash( "_list_counter", $counter + 1 );
        $counter++;
        if ( isset( $args[ "glue" ] ) ) {
            if (! empty( $content ) ) {
                $content .= $args[ "glue" ];
            }
        }
        $repeat = true;
    } else {
        $repeat = false;
    }
    return $content;
}
?>
