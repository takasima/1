<?php
function smarty_function_mtaltsearchcategoryids ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $categories = $app->param( 'categories' );
    $glue = $args[ 'glue' ];
    if (! $glue ) {
        $glue = ',';
    }
    if ( $categories ) {
        if (! is_array( $categories ) ) {
            $categories = preg_split( '/\s*,\s*/', $categories, -1, PREG_SPLIT_NO_EMPTY );
        }
    } else {
        $categories = array();
    }
    if ( $category ) {
        $categories[] = $category;
    }
    $i = 0;
    $category_ids = '';
    foreach ( $categories as $category_id ) {
        $category_id = intval( $category_id );
        if ( $category_id && ( preg_match( "/^[0-9]+$/", $category_id ) ) ) {
            $i++;
            if ( $i >= 2 ) {
                $category_ids .= $glue;
            }
            $category_ids .= $category_id;
        }
    }
    return $category_ids;
}
?>