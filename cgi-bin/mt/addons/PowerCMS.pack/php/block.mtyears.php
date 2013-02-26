<?php
function smarty_block_mtyears( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'year', 'vars', '_counter', 'currentyear' );
    $app = $ctx->stash( 'bootstrapper' );
    $param = array( 'args', 'ctx', 'content', 'repeat' );
    $app->delete_params( $param );
    require_once 'class.mt_entry.php';
    $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                  ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                  : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                      ? $_SERVER[ 'QUERY_STRING' ] : '' );
    parse_str( $param );
    $sort_order  = $args[ 'sort_order' ];
    $select_name = $args[ 'select_name' ];
    if ( $sort_order ) {
        if ( $sort_order == 'ascend' ){
            $sort_order = 'ASC';
            $max_order = 'DESC';
        } else {
            $sort_order = 'DESC';
            $max_order = 'ASC';
        }
    } else {
        $sort_order = 'ASC';
        $max_order = 'DESC';
    }
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $counter = 0;
    } else {
        $counter = $ctx->stash( '_counter' );
    }
    $vars = $ctx->stash( 'vars' );
    if ( isset( $vars ) ) {
        $blog = $ctx->stash( 'blog' );
        $blog_id = $blog->blog_id;
        $where = "entry_blog_id=$blog_id ORDER BY entry_authored_on $sort_order";
        $extra = array(
            'limit'  => 1,
            'offset' => 0,
        );
        $_entry = new Entry;
        $results = $_entry->Find( $where, false, false, $extra );
        $min = $results[0]->entry_authored_on;
        $where = "entry_blog_id=$blog_id ORDER BY entry_authored_on $max_order";
        $_entry = new Entry;
        $results = $_entry->Find( $where, false, false, $extra );
        $max = $results[0]->entry_authored_on;
        $min = substr( $min, 0, 4 );
        $max = substr( $max, 0, 4 );
        if ( ( $min == '' ) && ( $max == '' ) ) {
            return;
        }
        $vars = array();
        if ( $sort_order == 'DESC' ) {
            for ($i = $min; $i >= $max; $i--) {
                $vars[] = $i;
            }
        } else {
            for ($i = $min; $i <= $max; $i++) {
                $vars[] = $i;
            }
        }
        $ctx->stash( 'vars', $vars );
    } else {
        $counter = $ctx->stash( '_counter' );
    }
    if ( $counter < count( $vars ) ) {
        $year = $vars[ $counter ];
        $ctx->stash( 'year', $year );
        if ( $select_name == 'from_y' ) {
            if ( $from_y != '' ) {
                if ( $from_y == $year ) {
                    $ctx->stash( 'currentyear', 2 );
                } else {
                    $ctx->stash( 'currentyear', 1 );
                }
            } else {
                if ( $min == $year ) {
                    $ctx->stash( 'currentyear', 2 );
                } else {
                    $ctx->stash( 'currentyear', 1 );
                }
            }
        } elseif ( $select_name == 'to_y' ) {
            if ( $to_y != '' ) {
                if ( $to_y == $year ) {
                    $ctx->stash( 'currentyear', 2 );
                } else {
                    $ctx->stash( 'currentyear', 1 );
                }
            } else {
                if ( $max == $year ) {
                    $ctx->stash( 'currentyear', 2 );
                } else {
                    $ctx->stash( 'currentyear', 1 );
                }
            }
        }
        $ctx->stash( '_counter', $counter + 1 );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>
