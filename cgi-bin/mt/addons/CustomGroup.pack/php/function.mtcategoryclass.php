<?php
function smarty_function_mtcategoryclass( $args, $ctx ) {
    $cat = $ctx->stash( 'category' );
    if (! $cat ) return '';
    return $cat->category_class;
}
?>