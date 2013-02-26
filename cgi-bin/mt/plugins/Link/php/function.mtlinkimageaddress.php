<?php
function smarty_function_mtlinkimageaddress ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        return $link->image_address;
    }
}
?>