<?php
function smarty_block_mtconvertsjis( $args, $content, &$ctx, &$repeat ) {
    global $mt;
    $mt->config( 'PublishCharset', "shift_jis" );
    if ( isset( $content ) ) {
        if ( $args[ "z2h" ] ) {
            $content = mb_convert_kana( $content, 'ak', 'UTF-8' );
        }
        $content = mb_convert_encoding( $content, 'SJIS-WIN', 'UTF-8' );
    }
    return $content;
}
?>