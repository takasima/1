<?php
function smarty_function_mtaltsearchcategoryid ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $category = $app->param( 'category' );
    $category = intval( $category );
    if ( $category ) {
        if ( preg_match( "/^[0-9]+$/", $category ) ) {
            return $category;
        }
    }
}
?>