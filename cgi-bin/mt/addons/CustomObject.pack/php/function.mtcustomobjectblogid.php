<?php
function smarty_function_mtcustomobjectblogid ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        return $customobject->blog_id;
    }
}
?>