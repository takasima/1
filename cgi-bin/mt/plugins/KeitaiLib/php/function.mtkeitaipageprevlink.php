<?php
function smarty_function_mtkeitaipageprevlink ( $args, &$ctx ) {
    $page    = $ctx->stash( "_keitai_current" );
    $prev    = $page - 1;
    $request = $_SERVER[ "REQUEST_URI" ];
    if ( preg_match( "/\?/", $request) ) {
        $buf     = explode( "?", $request );
        $request = $buf[0];
    }
    // $_GET[ 'page'] = $prev;
    foreach ( $_GET as $key => $val ) {
        if ( $key == 'page' ) {
            if ( $prev != 1 ) {
                $param[] = "page=" . $prev;
            }
        } else {
            $param[] = $key . "=" . $val;
        }
    }
    if (! $param ) {
        if ( $prev != 1 ) {
            $param[] = "page=" . $prev;
        } else {
            return $request;
        }
    }
    return $request . "?" . implode( '&', $param );
}
?>