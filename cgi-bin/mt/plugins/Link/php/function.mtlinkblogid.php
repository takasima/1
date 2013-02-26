<?php
function smarty_function_mtlinkblogid ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        return $link->blog_id;
    }
}
?>