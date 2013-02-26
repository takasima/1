<?php
function smarty_function_mtcustomobjectcreatedon ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        $args[ 'ts' ] = $customobject->created_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>