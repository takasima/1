<?php
function smarty_block_mtcustomobjectfolder ( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'category' );
    if (! isset( $content ) ) {
        if ( $ctx->stash( 'category' ) ) {
            $ctx->stash( 'orig_category', $ctx->stash( 'category' ) );
        }
        $ctx->localize( $localvars );
        $customobject = $ctx->stash( 'customobject' );
        if (! isset( $customobject ) ) {
            return;
        }
        $category_id = $customobject->category_id;
        if ( $category_id > 0 ) {
            $category = $ctx->mt->db()->fetch_folder( $category_id );
            if ( $category ) {
                $ctx->stash( 'category', $category );
            }
        }
    } else {
        $ctx->restore( $localvars );
        if ( $ctx->stash( 'orig_category' ) ) {
            $ctx->stash( 'category', $ctx->stash( 'orig_category' ) );
        } else {
            $ctx->stash( 'category', NULL );
        }
        $ctx->stash( 'orig_category', NULL );
    }
    return $content;
}
?>