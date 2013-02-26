<?php
function smarty_function_mtitemgroupcategoriescount( $args, $ctx ) {
    $content = NULL;
    $repeat = TRUE;
    $args[ 'count' ] = 1;
    require_once 'block.mtgroupcategoriesfolders.php';
    return smarty_block_mtgroupcategoriesfolders( $args, $content, $ctx, $repeat );
}
?>
