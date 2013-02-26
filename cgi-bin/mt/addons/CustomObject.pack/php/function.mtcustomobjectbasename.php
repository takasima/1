<?php
function smarty_function_mtcustomobjectbasename ( $args, &$ctx ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        $basename = $customobject->basename;
        $sep = $args[ 'separator' ];
        if ( $sep == '-' ) {
            $basename = preg_replace( "/_/", '-', $basename );
        } elseif ( $sep == '_' ) {
            $basename = preg_replace( "/\-/", '_', $basename );
        }
    }
    return $basename;
}
?>