<?php
function smarty_function_mtlinkauthoredon ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $link->authored_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>