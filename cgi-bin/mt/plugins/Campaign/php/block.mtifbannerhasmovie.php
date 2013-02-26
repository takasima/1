<?php
function smarty_block_mtifbannerhasmovie ($args, $content, &$ctx, &$repeat) {
    require_once( 'block.mtifcampaignhasmovie.php' );
    return smarty_block_mtifcampaignhasmovie( $args, $content, $ctx, $repeat );
}
