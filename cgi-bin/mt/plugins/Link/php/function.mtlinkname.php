<?php
function smarty_function_mtlinkname ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        return $link->name;
    }
}
?>