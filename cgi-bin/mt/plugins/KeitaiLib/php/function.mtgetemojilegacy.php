<?php
function smarty_function_mtgetemojilegacy ( $args, &$ctx ) {
    $docomo_id = $args[ 'docomo_id' ];
    $agent = $_SERVER[ 'HTTP_USER_AGENT' ];
    $emoji;
    if ( preg_match( '/DoCoMo/', $agent ) ) {
        require_once( 'emoji_docomo2docomo_legacy.php' );
        $emoji = get_docomo_legacy( $docomo_id );
    } elseif ( preg_match ( '/UP\.Browser/', $agent ) ) {
        require_once( 'emoji_docomo2au_legacy.php' );
        $emoji = get_au_legacy( $docomo_id );
    } elseif ( ( preg_match ( '/SoftBank/', $agent ) ) ||
               ( preg_match ( '/Vodafone/', $agent ) ) ) {
        require_once( 'emoji_docomo2softbank.php' );
        $emoji = get_softbank( $docomo_id );
        if ( preg_match ( '/^E/', $emoji ) ) {
            $emoji = "&#x$emoji;";
        }
    } else {
        $emoticon = $args[ 'emoticon' ];
        if ( $emoticon ) {
            require_once( 'function.mtgetemoticon.php' );
            return smarty_function_mtgetemoticon( $args, $ctx );
        }
    }
    return $emoji;
}
?>