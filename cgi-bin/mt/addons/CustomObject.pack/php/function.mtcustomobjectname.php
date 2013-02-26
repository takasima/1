<?php
function smarty_function_mtcustomobjectname ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        return $customobject->name;
    }
}
?>