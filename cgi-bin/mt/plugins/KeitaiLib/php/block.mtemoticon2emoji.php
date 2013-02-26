<?php
function smarty_block_mtemoticon2emoji( $args, $content, &$ctx, &$repeat ) {
    require_once( 'function.mtgetemoji.php' );
    require_once( 'emoji_emoticon2docomo.php' );
    $charset = $args[ 'charset' ];
    $base = $args[ 'base' ];
    $base = preg_quote( $base, '!' );
    if (! isset( $charset ) ) {
        $args[ 'charset' ] = 'unicode';
    }
    preg_match_all( '/<img(?:[ \t\n\r][^>]*)?>/i', $content, $match );
    $match = $match[0];
    for ( $i = 0 ; $i < count( $match ); $i++ ) {
        if ( preg_match( '/src\s*="(.*?)"/is', $match[$i], $src ) ) {
            $path = $src[1];
            $basename = basename( $path );
            $basename = preg_quote( $basename );
            if ( preg_match( "!$base$basename$!is", $path ) ) {
                $basename = basename( $path );
                $basename = preg_replace( '/\..*$/is', '', $basename );
                $id = get_id_from_basename( $basename );
                if ( $id ) {
                    $args[ 'docomo_id' ] = $id;
                    $emoji = smarty_function_mtgetemoji( $args, $ctx );
                    $search = preg_quote( $match[$i], '!' );
                    if ( $emoji ) {
                        $content = preg_replace( "!$search!", $emoji, $content );
                    }
                }
            }
        }
    }
    return $content;
}
?>