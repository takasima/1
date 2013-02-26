<?php
function smarty_modifier_hilight( $text ) {
    require_once( 'modifier.highlight.php' );
    return smarty_modifier_highlight( $text );
}
?>