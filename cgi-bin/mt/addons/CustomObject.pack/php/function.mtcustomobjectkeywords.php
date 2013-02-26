<?php
function smarty_function_mtcustomobjectkeywords ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        return $customobject->keywords;
    }
}
?>