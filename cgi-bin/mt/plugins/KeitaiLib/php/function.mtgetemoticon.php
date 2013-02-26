<?php
function smarty_function_mtgetemoticon( $args, &$ctx ) {
    $docomo_id   = $args[ 'docomo_id' ];
    $require_alt = $args[ 'alt' ];
    $base        = $args[ 'base' ];
    $size        = $args[ 'size' ];
    if ( empty( $size ) ) {
        $size = '12';
    }
    require_once 'emoji_docomo2emoticon.php';
    list( $alt, $icon ) = get_icon( $docomo_id );
    if ( $icon ) {
        if (! $require_alt ) {
            $alt = '';
        }
        return "<img alt=\"$alt\" src=\"$base$icon\" width=\"$size\" height=\"$size\" />";
    }
    if ( $require_alt ) {
        return "[$alt]";
    }
    return '';
}
?>