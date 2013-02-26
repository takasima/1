<?php
function smarty_function_mtcustomobjectbody ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        return $customobject->body;
    }
}
?>