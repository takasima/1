<?php
function smarty_block_mtlinkblock ( $args, $content, &$ctx, $repeat ) {
    $localvars = array( 'link' );
    $id = intval( $args[ 'id' ] );
    $blog_id = intval( $args[ 'blog_id' ] );
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    } else {
        $blog    = $ctx->mt->db()->fetch_blog( $blog_id );
        $blog_id = $blog->id;
    }
    require_once 'class.mt_link.php';
    $where = "link_blog_id={$blog_id} AND link_status=2";
    if ( isset( $id ) ) {
        $where = "link_status=2 AND link_id='{$id}'";
    }
    $extra[ 'limit' ] = 1;
    $_link = new Link;
    $link = $_link->Find( $where, false, false, $extra );
    if ( isset( $link ) ) {
        $link = $link[0];
        $ctx->stash( 'link', $link );
    } else {
        return '';
    }
    return $content;
}
?>