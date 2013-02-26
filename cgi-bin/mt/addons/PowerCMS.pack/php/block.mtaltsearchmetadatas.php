<?php
function smarty_block_mtaltsearchmetadatas( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtaltsearchmetadata.php' );
    return smarty_block_mtaltsearchmetadata( $args, $content, $ctx, $repeat );
}
?>