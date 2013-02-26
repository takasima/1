<?php
function smarty_modifier_convert2thumbnail( $text, $arg ) {
    if ( strpos( $arg, ',' ) ) {
        list( $embed, $link, $dimension ) = explode( ',', $arg );
        $link  = trim ( $link );
        $dimension = trim ( $dimension );
    } else {
        $embed = $arg;
        $link = NULL;
    }
    if (! $dimension ) {
        $dimension = 'width';
    }
    $embed = trim ( $embed );
    return convert2thumbnail( $text, 'auto', $embed, $link, $dimension );
}
?>