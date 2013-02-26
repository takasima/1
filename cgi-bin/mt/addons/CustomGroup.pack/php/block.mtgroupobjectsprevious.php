<?php
function smarty_block_mtgroupobjectsprevious( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'previous_currentobject' );
    $stash = $ctx->stash( '____stash' );
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $previous_currentobject = $ctx->stash( $stash );
        $object = $ctx->stash( 'previousobject' );
        if (! $object ) {
            $repeat = FALSE;
            return '';
        }
        $ctx->stash( 'previous_currentobject', $previous_currentobject );
        $ctx->stash( $stash, $object );
    } else {
        $ctx->stash( $stash, $ctx->stash( 'previous_currentobject' ) );
        $ctx->restore( $localvars );
    }
    return $content;
}
?>