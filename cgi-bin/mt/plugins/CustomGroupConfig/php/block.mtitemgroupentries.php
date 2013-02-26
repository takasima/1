<?php
function smarty_block_mtitemgroupentries ( $args, $content, &$ctx, &$repeat ) {
    require_once 'block.mtgroupentriespages.php';
    return smarty_block_mtgroupentriespages( $args, $content, $ctx, $repeat );
}
?>
