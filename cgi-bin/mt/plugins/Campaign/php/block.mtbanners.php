<?php
function smarty_block_mtbanners ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaigns.php' );
    return smarty_block_mtcampaigns( $args, $content, $ctx, $repeat );
}
?>