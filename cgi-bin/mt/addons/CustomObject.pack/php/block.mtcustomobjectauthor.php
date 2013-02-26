<?php
function smarty_block_mtcustomobjectauthor( $args, $content, &$ctx, &$repeat ) {
    $customobject = $ctx->stash( 'customobject' );
    if ( isset( $customobject ) ) {
        $author_id = $customobject->author_id;
        require_once( 'class.mt_author.php' );
        $_author = new Author;
        $where = " author_id = $author_id and author_status = 1";
        $extra = array(
            'limit' => 1,
        );
        $author = $_author->Find( $where, false, false, $extra );
        if ( isset( $author ) ) {
            $author = $author[ 0 ];
            $ctx->stash( 'author', $author );
        } else {
            return '';
        }
    }
    return $content;
}
?>