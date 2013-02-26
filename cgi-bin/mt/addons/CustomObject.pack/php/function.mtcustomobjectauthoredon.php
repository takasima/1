<?php
function smarty_function_mtcustomobjectauthoredon ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        $args[ 'ts' ] = $customobject->authored_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>