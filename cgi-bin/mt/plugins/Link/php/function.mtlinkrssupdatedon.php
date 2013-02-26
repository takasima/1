<?php
function smarty_function_mtlinkrssupdatedon ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $link->rssupdated_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>