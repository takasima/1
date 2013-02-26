<?php
function smarty_block_mtitemgroupcategories ( $args, $content, &$ctx, &$repeat ) {
    require_once 'block.mtgroupcategoriesfolders.php';
    return smarty_block_mtgroupcategoriesfolders( $args, $content, $ctx, $repeat );
}
?>
