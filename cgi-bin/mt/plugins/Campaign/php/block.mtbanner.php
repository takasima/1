<?php
function smarty_block_mtbanner ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaign.php' );
    return smarty_block_mtcampaign( $args, $content, $ctx, $repeat );
}
?>