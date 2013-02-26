<?php
function smarty_block_mtbannertags( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtcampaigntags.php' );
    return smarty_block_mtcampaigntags( $args, $content, $ctx, $repeat );
}
?>