<?php
function smarty_function_mtlinkrssaddress ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        return $link->rss_address;
    }
}
?>