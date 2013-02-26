<?php
function smarty_function_mtaltsearchblogid ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $blog_id = $app->param( 'blog_id' );
    $blog_id = intval( $blog_id );
    if ( $blog_id ) {
        if ( preg_match( "/^[0-9]+$/", $blog_id ) ) {
            return $blog_id;
        }
    }
}
?>