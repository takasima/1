<?php
function smarty_block_mtifbannerhasimage ($args, $content, &$ctx, &$repeat) {
    require_once( 'block.mtifcampaignhasimage.php' );
    return smarty_block_mtifcampaignhasimage( $args, $content, $ctx, $repeat );
}
