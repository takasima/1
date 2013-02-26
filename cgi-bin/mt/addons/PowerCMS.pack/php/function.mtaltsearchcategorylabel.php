<?php
function smarty_function_mtaltsearchcategorylabel ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $archive_title = $ctx->stash( 'archive_title' );
    if ( $archive_title ) {
        return $archive_title;
    } else {
        $category = $app->param( 'category' );
        $category = intval( $category );
        if ( $category ) {
            if ( preg_match( "/^[0-9]+$/", $category ) ) {
                require_once 'class.mt_category.php';
                $where = "category_id={$category} ";
                $_cat = new Category;
                $cats = $_cat->Find( $where );
                foreach ( $cats as $c ) {
                    return $c->label;
                }
            }
        }
    }
}
?>