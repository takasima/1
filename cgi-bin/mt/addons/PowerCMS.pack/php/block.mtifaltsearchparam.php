<?php
function smarty_block_mtifaltsearchparam ( $args, $content, $ctx, $repeat ) {
    $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                  ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                  : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                      ? $_SERVER[ 'QUERY_STRING' ] : '' );
    parse_str( $param, $params );
    $values = (array)$params[ $args[ 'name' ] ];
    if ( array_key_exists( 'eq', $args ) ) {
        if ( in_array($args[ 'eq' ], $values ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    } /* Backward compatibility */ elseif ( array_key_exists( 'value', $args ) ) {
        if ( in_array( $args[ 'value' ], $values ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    } elseif ( array_key_exists( 'ne', $args ) ) {
        if (! in_array( $args[ 'ne' ], $values ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    } elseif ( array_key_exists( 'lt', $args ) ) {
        foreach ( $values as $key => $value ) {
            if ( $value < $args[ 'lt' ]) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        }
    } elseif ( array_key_exists( 'gt', $args ) ) {
        foreach ( $values as $key => $value ) {
            if ( $value > $args[ 'gt' ] ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        }
    } elseif ( array_key_exists( 'le', $args ) ) {
        foreach ( $values as $key => $value ) {
            if ( $value <= $args[ 'le' ] ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        }
    } elseif ( array_key_exists( 'ge', $args ) ) {
        foreach ( $values as $key => $value ) {
            if ( $value >= $args[ 'ge' ] ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        }
    } elseif ( array_key_exists( 'like', $args ) ) {
        foreach ( $values as $key => $value ) {
            $patt = $args[ 'like' ];
            $opt = "";
            if ( preg_match( "/^\/.+\/([si]+)?$/", $patt, $matches ) ) {
                $patt = preg_replace( "/^\/|\/([si]+)?$/", "", $patt );
                if ( $matches[ 1 ] )
                    $opt = $matches[ 1 ];
            } else {
                $patt = preg_replace( "!/!", "\\/", $patt );
            }
            if ( preg_match( "/$patt/$opt", $value ) ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>
