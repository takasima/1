<?php
function smarty_block_mtifaltsearchparamdate ( $args, $content, $ctx, $repeat ) {
    require_once 'class.mt_entry.php';
    $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                  ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                  : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                      ? $_SERVER[ 'QUERY_STRING' ] : '' );
    parse_str( $param, $params );
    $value = $args[ 'value' ];
    $name  = $args[ 'name' ];
    if ( $params[ $name ] != '' ) {
        if ( preg_match( "/$value/i", $params[ $name ] ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        } else {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
        }
    } else {
        $blog = $ctx->stash( 'blog' );
        $blog_id = $blog->blog_id;
        $where = "entry_blog_id=$blog_id ORDER BY entry_authored_on ASC";
        $extra = array(
            'limit' => 1,
            'offset' => 0,
        );
        $_entry = new Entry;
        $results = $_entry->Find( $where, false, false, $extra );
        $min = $results[0]->entry_authored_on;
        $where = "entry_blog_id=$blog_id ORDER BY entry_authored_on DESC";
        $_entry = new Entry;
        $results = $_entry->Find( $where, false, false, $extra );
        $max = $results[0]->entry_authored_on;
        $min = str_replace( '-', '', $min );
        $max = str_replace( '-', '', $max );
        $return_val = 0;
        if ( $name == 'from_y' ) {
            if ( $value == substr( $min, 0, 4 ) ) {
                $return_val = 1;
            }
        } elseif ( $name == 'from_m' ) {
            if ( $value == substr( $min, 4, 2 ) ) {
                $return_val = 1;
            }
        } elseif ( $name == 'from_d' ) {
            if ( $value == substr( $min, 6, 2 ) ) {
                $return_val = 1;
            }
        } elseif ( $name == 'to_y' ) {
            if ( $value == substr( $max, 0, 4 ) ) {
                $return_val = 1;
            }
        } elseif ($name == 'to_m') {
            if ( $value == substr( $max, 4, 2 ) ) {
                $return_val = 1;
            }
        } elseif ( $name == 'to_d' ) {
            if ( $value == substr( $max, 6, 2 ) ) {
                $return_val = 1;
            }
        }
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $return_val );
    }
}
?>
