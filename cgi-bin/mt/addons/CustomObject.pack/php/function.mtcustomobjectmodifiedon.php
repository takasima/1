<?php
function smarty_function_mtcustomobjectmodifiedon ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        $args[ 'ts' ] = $customobject->modified_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>