<?php
function smarty_block_mtstriplinefeeds( $args, $content, &$ctx, &$repeat ) {
    require_once( 'modifier.strip_linefeeds.php' );
    return smarty_modifier_strip_linefeeds( $content );
}
?>