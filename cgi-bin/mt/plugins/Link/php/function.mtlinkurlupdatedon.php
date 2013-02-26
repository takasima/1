<?php
function smarty_function_mtlinkurlupdatedon ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $link->urlupdated_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>