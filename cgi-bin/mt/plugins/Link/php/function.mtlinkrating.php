<?php
function smarty_function_mtlinkrating ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        return $link->rating;
    }
}
?>