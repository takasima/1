<?php
function smarty_function_mtkeitaiemoticonsize ( $args, $ctx ) {
    $config = $ctx->mt->db()->fetch_plugin_data( 'keitailib', "configuration" );
    $size = isset( $config[ 'emoticon_size' ] ) ? $config[ 'emoticon_size' ] : 16;
    $size = intval( $size );
    return $size;
}
?>