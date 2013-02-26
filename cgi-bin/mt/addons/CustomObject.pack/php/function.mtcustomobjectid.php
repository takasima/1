<?php
function smarty_function_mtcustomobjectid ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        return $customobject->id;
    }
}
?>