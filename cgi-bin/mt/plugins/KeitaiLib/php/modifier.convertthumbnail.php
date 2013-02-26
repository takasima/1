<?php
function smarty_modifier_convertthumbnail( $text, $arg ) {
    require_once( 'modifier.convert2thumbnail.php' );
    return smarty_modifier_convert2thumbnail( $text, $arg );
}
?>