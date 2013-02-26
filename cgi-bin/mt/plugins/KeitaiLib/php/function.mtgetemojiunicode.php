<?php
function smarty_function_mtgetemojiunicode ( $args, &$ctx ) {
    $docomo_id = $args[ 'docomo_id' ];
    $agent = $_SERVER[ 'HTTP_USER_AGENT' ];
    $emoji;
    if ( preg_match( '/DoCoMo/', $agent ) ) {
        require_once( 'emoji_docomo2docomo.php' );
        $emoji = get_docomo( $docomo_id );
    } elseif ( preg_match ( '/UP\.Browser/', $agent ) ) {
        require_once( 'emoji_docomo2au.php' );
        $emoji = get_au( $docomo_id );
    } elseif ( ( preg_match ( '/SoftBank/', $agent ) ) ||
               ( preg_match ( '/Vodafone/', $agent ) ) ) {
        require_once( 'emoji_docomo2softbank.php' );
        $emoji = get_softbank( $docomo_id );
    } else {
        $emoticon = $args[ 'emoticon' ];
        if ( $emoticon ) {
            require_once( 'function.mtgetemoticon.php' );
            return smarty_function_mtgetemoticon( $args, $ctx );
        }
    }
    if ( preg_match ( '/^E/', $emoji ) ) {
        $emoji = "&#x$emoji;";
    }
    return $emoji;
}
?>