<?php
function smarty_function_mtaltsearchcategories_and_or ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $categories_and_or = $app->param( 'categories_and_or' );
    if ( ( $categories_and_or == 'and' ) || ( $categories_and_or == 'or' ) ) {
        return $categories_and_or;
    }
}
?>