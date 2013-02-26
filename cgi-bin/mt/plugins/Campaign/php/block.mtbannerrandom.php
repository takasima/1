<?php
function smarty_block_mtbannerrandom ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaignrandom.php' );
    return smarty_block_mtcampaignrandom( $args, $content, $ctx, $repeat );
}
?>