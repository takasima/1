<?php
function smarty_function_mtaltsearchsort_order ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $sort_order = $app->param( 'sort_order' );
    if ( ( $sort_order == 'ascend' ) || ( $sort_order == 'descend' ) ) {
        return $sort_order;
    }
}
?>