<?php
require_once('function.mtblogurl.php');
function smarty_block_mtmembersformobile($args, $content, &$ctx, &$repeat) {

    $blog = $ctx->stash( 'blog' );

    $buf = array(
        'blog_id' => $blog->blog_id
    );

    $site_url = smarty_function_mtblogurl($buf, $ctx);
//    $site_url = $blogblog_site_url;
    $site_url = preg_replace( '/\/$/', '', $site_url );

    $q_site_url = preg_quote( $site_url, '/' );
    $index = $args[ 'index' ];

    if ( $args[ 'dynamic' ] ) {
        $sess_id = $_REQUEST[ 'sess_id' ];
        $content = preg_replace( '/(href=")(.*?)(")/e', "'href=\"' . _link_for_members_in_dynamic( '$2', '$q_site_url', '$index', '$sess_id' ) . '\"'", $content );
    } else {
        $content = preg_replace( '/(href=")(.*?)(")/e', "'href=\"' . _link_for_members( '$2', '$q_site_url', '$index' ) . '\"'", $content );
    }
    return $content;
}

function _link_for_members( $url, $q_site_url, $index ) {
    if ( preg_match( '/^javascript/', $url ) ||
         preg_match( '/^mailto/', $url ) ||
         ( preg_match( '/^https?/', $url ) && !( preg_match( '/' . $q_site_url . '/', $url ) ) )
    ) {
        return $url;
    }
    if ( preg_match( '/^(.*?)([#\?].*)$/', $url, $matches ) ) {
        $url = $matches[ 1 ];
        if ( preg_match( '/\/$/', $url ) ) {
            $url .= $index;
        }
        $param = $matches[ 2 ];
        if ( preg_match( '/^(#.*?)$/', $param, $matches2 ) ) {
            $url .= '<?php if ( $sess_id ) { echo "?sess_id=$sess_id"; } ?>';
            $url .= $matches2[ 1 ];
        } else if ( preg_match( '/^(\?.*?)$/', $param ) ) {
            if ( preg_match( '/^(\?.*?)(#.*?)$/', $param, $matches3 ) ) {
                $url .= $matches3[ 1 ];
                $url .= '<?php if ( $sess_id ) { echo "&sess_id=$sess_id"; } ?>';
                $url .= $matches3[ 2 ];
            } else {
                $url .= $param . '<?php if ( $sess_id ) { echo "&sess_id=$sess_id"; } ?>';
            }
        }
    } else {
        if ( preg_match( '/\/$/', $url ) ) {
            $url .= $index;
        }
        $url .= '<?php if ( $sess_id ) { echo "?sess_id=$sess_id"; } ?>';
    }
    return $url;
}
function _link_for_members_in_dynamic( $url, $q_site_url, $index, $sess_id ) {
    if ( preg_match( '/^javascript/', $url ) ||
         preg_match( '/^mailto/', $url ) ||
         ( preg_match( '/^https?/', $url ) && !( preg_match( '/' . $q_site_url . '/', $url ) ) )
    ) {
        return $url;
    }
    if ( preg_match( '/^(.*?)([#\?].*)$/', $url, $matches ) ) {
        $url = $matches[ 1 ];
        if ( preg_match( '/\/$/', $url ) ) {
            $url .= $index;
        }
        $param = $matches[ 2 ];
        if ( preg_match( '/^(#.*?)$/', $param, $matches2 ) ) {
            $url .= "?sess_id=$sess_id";
            $url .= $matches2[ 1 ];
        } else if ( preg_match( '/^(\?.*?)$/', $param ) ) {
            if ( preg_match( '/^(\?.*?)(#.*?)$/', $param, $matches3 ) ) {
                $url .= $matches3[ 1 ];
                $url .= "&sess_id=$sess_id";
                $url .= $matches3[ 2 ];
            } else {
                $url .= $param . "&sess_id=$sess_id";
            }
        }
    } else {
        if ( preg_match( '/\/$/', $url ) ) {
            $url .= $index;
        }
        $url .= "?sess_id=$sess_id";
    }
    return $url;
}
?>
