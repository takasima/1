<?php
function smarty_function_mtkeitaipagelink ( $args, &$ctx ) {
    $page    = $ctx->stash( '_list_counter' );
    $request = $_SERVER[ 'REQUEST_URI' ];
    if ( preg_match( '/\?/', $request ) ) {
        $buf     = explode( '?', $request );
        $request = $buf[0];
    }
    $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                  ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                  : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                      ? $_SERVER[ 'QUERY_STRING' ] : '' );
    if ( $param === '' ) {
        $param = "page={$page}";
    } else {
        $param = preg_replace( "/page=[0-9]{1,}/", "page={$page}", $param );
    }
    return $request . "?{$param}";
}
?>
