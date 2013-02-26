<?php
function smarty_function_mtlinkmodifiedon ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $link->modified_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>