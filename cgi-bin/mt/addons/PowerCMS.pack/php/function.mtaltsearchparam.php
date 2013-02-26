<?php
function smarty_function_mtaltsearchparam ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $param = array( 'args', 'ctx' );
    $app->delete_params( $param );
    $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                  ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                  : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                      ? $_SERVER[ 'QUERY_STRING' ] : '' );
    parse_str( $param, $params );
    $name = $args[ 'name' ];
    if ( $args[ 'pass' ] ) {
        $array = ( array )$params[ $name ];
    } else {
        $array = array_map( 'htmlspecialchars', ( array )$params[ $name ] );
    }
    $query = implode($args[ 'glue' ], $array );
    $query = str_replace( '\\', '', $query );
    return $query;
}
?>
