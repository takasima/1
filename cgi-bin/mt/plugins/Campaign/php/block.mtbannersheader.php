<?php
function smarty_block_mtbannersheader ( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaignsheader.php' );
    return smarty_block_mtcampaignsheader( $args, $content, $ctx, $repeat );
}
?>