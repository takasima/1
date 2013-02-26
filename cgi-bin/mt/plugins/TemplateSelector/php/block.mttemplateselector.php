<?php
function smarty_block_mttemplateselector( $args, $content, &$ctx, &$repeat ) {
    require_once( 'block.mtiftemplateselector.php' );
    return smarty_block_mtiftemplateselector( $args, $content, $ctx, $repeat );
}
?>