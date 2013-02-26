<?php
function smarty_block_mtifaltsearchparamarray ( $args, $content, $ctx, $repeat ) {
    $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                  ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                  : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                      ? $_SERVER[ 'QUERY_STRING' ] : '' );
    parse_str( $param, $params );
    $value = $args[ 'value' ];
    $name  = $args[ 'name' ];
    $array = $params[ $name ];
    if (! $array ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
    if ( in_array( $value, $array ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>
