<?php
function smarty_block_mtbannerasset( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaignasset.php' );
    return smarty_block_mtcampaignasset( $args, $content, $ctx, $repeat );
}
?>