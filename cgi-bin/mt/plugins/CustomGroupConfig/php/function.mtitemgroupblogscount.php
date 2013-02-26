<?php
function smarty_function_mtitemgroupblogscount( $args, $ctx ) {
    $content = NULL;
    $repeat = TRUE;
    $args[ 'count' ] = 1;
    require_once 'block.mtgroupblogswebsites.php';
    return smarty_block_mtgroupblogswebsites( $args, $content, $ctx, $repeat );
}
?>
