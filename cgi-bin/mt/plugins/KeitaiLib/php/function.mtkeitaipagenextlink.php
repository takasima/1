<?php
function smarty_function_mtkeitaipagenextlink ( $args, &$ctx ) {
    $page    = $ctx->stash( "_keitai_current" );
    $next    = $page + 1;
    $request = $_SERVER[ "REQUEST_URI" ];
    if ( preg_match( "/\?/", $request ) ) {
        $buf     = explode( "?", $request );
        $request = $buf[0];
    }
    // $_GET[ 'page'] = $next;
    $param = NULL;
    foreach ( $_GET as $key => $val ) {
        if ( $key == 'page' ) {
            $param[] = "page=" . $next;
        } else {
            $param[] = $key . "=" . $val;
        }
    }
    if (! $param ) {
        $param[] = "page=" . $next;
    }
    return $request . "?" . implode( '&', $param );
}
?>