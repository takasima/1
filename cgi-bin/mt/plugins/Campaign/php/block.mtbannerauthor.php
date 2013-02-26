<?php
function smarty_block_mtbannerauthor ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaignauthor.php' );
    return smarty_block_mtcampaignauthor( $args, $content, $ctx, $repeat );
}
?>