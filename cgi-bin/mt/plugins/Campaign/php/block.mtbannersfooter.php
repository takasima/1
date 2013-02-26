<?php
function smarty_block_mtbannersfooter ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaignsfooter.php' );
    return smarty_block_mtcampaignsfooter( $args, $content, $ctx, $repeat );
}
?>