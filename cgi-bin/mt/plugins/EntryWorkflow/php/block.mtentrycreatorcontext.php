<?php
function smarty_block_mtentrycreatorcontext( $args, $content, &$ctx, &$repeat ) {
    $entry = $ctx->stash( 'entry' );
    if (! $entry ) {
        return $ctx->error( "No entry available" );
    }
    $author_id = $entry->creator_id;
    $author;
    if ( $author_id ) {
        $author = $ctx->mt->db()->fetch_author( $author_id );
    }
    if (! isset ( $author ) ) {
        $author = $entry->author();
    }
    if ( isset ( $author ) ) {
        $ctx->stash( 'author', $author );
    } else {
        $repeat = false;
    }
    return $content;
}
?>