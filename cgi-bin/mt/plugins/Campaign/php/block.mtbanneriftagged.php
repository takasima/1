<?php
function smarty_block_mtbanneriftagged( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaigniftagged.php' );
    return smarty_block_mtcampaigniftagged( $args, $content, $ctx, $repeat );
}
?>
