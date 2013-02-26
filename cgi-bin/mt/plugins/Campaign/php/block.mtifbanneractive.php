<?php
function smarty_block_mtifbanneractive ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtifcampaignactive.php' );
    return smarty_block_mtifcampaignactive( $args, $content, $ctx, $repeat );
}
?>