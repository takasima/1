<?php
function smarty_modifier_z2h( $text, $arg ) {
    $text = mb_convert_kana( $text, 'aks', 'UTF-8' );
    require_once( 'powercms_professional_util_func.php' );
    $text = z2h_kigou( $text );
    return $text;
}
?>