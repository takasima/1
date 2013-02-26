<?php
function smarty_block_mtgroupobjectsnext( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'next_currentobject' );
    $stash = $ctx->stash( '____stash' );
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $next_currentobject = $ctx->stash( $stash );
        $object = $ctx->stash( 'nextobject' );
        if (! $object ) {
            $repeat = FALSE;
            return '';
        }
        $ctx->stash( 'next_currentobject', $next_currentobject );
        $ctx->stash( $stash, $object );
    } else {
        $ctx->stash( $stash, $ctx->stash( 'next_currentobject' ) );
        $ctx->restore( $localvars );
    }
    return $content;
}
?>