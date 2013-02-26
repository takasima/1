<?php
function smarty_function_mtitemgroupentriescount( $args, $ctx ) {
    $content = NULL;
    $repeat = TRUE;
    $args[ 'count' ] = 1;
    require_once 'block.mtgroupentriespages.php';
    return smarty_block_mtgroupentriespages( $args, $content, $ctx, $repeat );
}
?>
