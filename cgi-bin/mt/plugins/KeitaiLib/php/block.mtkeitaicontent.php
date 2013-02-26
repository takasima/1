<?php
function smarty_block_mtkeitaicontent( $args, $content, &$ctx, &$repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $localvars = array( '_start_tag', '_size', '_page' );
    if (! isset( $args[ "start_tag" ] ) || ! isset( $args[ "size" ] ) ) {
        return $content;
    }
    if (! isset( $content ) ) {
        $page = $app->param( 'page' );
        if (! isset( $page ) ) {
            $page = 1;
        }
        $ctx->stash( "_split_start_tag", $args[ "start_tag" ] );
        $ctx->stash( "_keitai_size", $args[ "size" ] );
        $ctx->stash( "_keitai_current", $page );
    }
    return $content;
}
?>