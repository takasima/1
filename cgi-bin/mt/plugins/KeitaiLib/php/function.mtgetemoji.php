<?php
function smarty_function_mtgetemoji ( $args, &$ctx ) {
    $charset = $args[ 'charset' ];
    if (! isset( $charset ) ) {
        $charset = 'unicode';
    }
    if ( $charset == 'unicode' ) {
        require_once( 'function.mtgetemojiunicode.php' );
        return smarty_function_mtgetemojiunicode( $args, $ctx );
    } else if ( $charset == 'regacy' ) {
        require_once( 'function.mtgetemojiregacy.php' );
        return smarty_function_mtgetemojiregacy( $args, $ctx );
    } else if ( $charset == 'legacy' ) {
        require_once( 'function.mtgetemojilegacy.php' );
        return smarty_function_mtgetemojilegacy( $args, $ctx );
    } else if ( $charset == 'emoticon' ) {
        require_once( 'function.mtgetemoticon.php' );
        return smarty_function_mtgetemoticon( $args, $ctx );
    }
}
?>