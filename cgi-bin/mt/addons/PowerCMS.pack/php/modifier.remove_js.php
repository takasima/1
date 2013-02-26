<?php
function smarty_modifier_remove_js( $text ) {
    if ( preg_match( '/<script.*?\/script>/si', $text ) ) {
        $text = preg_replace( '/<script.*?\/script>/si', '', $text );
    }
    return $text;
}
?>