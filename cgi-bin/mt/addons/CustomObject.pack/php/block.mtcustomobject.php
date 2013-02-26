<?php
function smarty_block_mtcustomobject ( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'customobject' );
    $id = $args[ 'id' ];
    $blog_id = $args[ 'blog_id' ];
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    } else {
        $blog    = $ctx->mt->db()->fetch_blog( $blog_id );
        $blog_id = $blog->id;
    }
    include_once( 'customobject.util.php' );
    $prefix = __init_customobject_class ( $ctx );
    $include_draft = '';
    if (! $args[ 'include_draft' ] ) {
        $include_draft = " AND {$prefix}_status = 2 ";
    }
    $where = "{$prefix}_blog_id={$blog_id} {$include_draft}";
    if ( isset( $id ) ) {
        $where = " {$prefix}_id='{$id}' $include_draft";
    }
    $extra[ 'limit' ] = 1;
    $_customobject = new CustomObject;
    $customobject = $_customobject->Find( $where, false, false, $extra );
    if ( isset( $customobject ) ) {
        $customobject = $customobject[ 0 ];
        $ctx->stash( 'customobject', $customobject );
        if ( is_object( $customobject ) ) {
            $local_blog_id = $customobject->blog_id;
            $ctx->stash( 'blog', $ctx->mt->db()->fetch_blog( $local_blog_id ) );
            $ctx->stash( 'blog_id', $local_blog_id );
        }
    } else {
        $repeat = FALSE;
        return '';
    }
    return $content;
}
?>