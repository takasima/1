<?php
function smarty_function_mttrans( $args, &$ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $phrase = $args[ 'phrase' ];
    $params = $args[ 'params' ];
    if ( strpos($params, '%%') !== false ) {
        $params = explode( '%%', $params );
    }
    if ( isset ( $app ) ) {
        return $app->translate( $phrase, $params );
    }
    return $ctx->mt->translate( $phrase, $params );
}
?>
