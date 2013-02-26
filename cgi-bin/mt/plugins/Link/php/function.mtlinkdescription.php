<?php
function smarty_function_mtlinkdescription ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        return $link->description;
    }
}
?>