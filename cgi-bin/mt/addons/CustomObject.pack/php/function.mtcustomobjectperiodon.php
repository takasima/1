<?php
function smarty_function_mtcustomobjectperiodon ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        $args[ 'ts' ] = $customobject->period_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>