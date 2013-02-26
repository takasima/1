<?php
function smarty_block_mtitemgroupblogs ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtgroupblogswebsites.php' );
    return smarty_block_mtgroupblogswebsites( $args, $content, $ctx, $repeat );
}
?>