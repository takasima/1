<?php
function smarty_function_mtlinkcreatedon ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $link->created_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>