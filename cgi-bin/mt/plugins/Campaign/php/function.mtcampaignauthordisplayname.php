<?php
function smarty_function_mtcampaignauthordisplayname ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $author_id = $campaign->author_id;
        require_once( 'class.mt_author.php' );
        $_author = new Author;
        $where = " author_id = $author_id and author_status = 1";
        $extra = array(
            'limit' => 1,
        ); 
        $author = $_author->Find( $where, false, false, $extra );
        if ( isset( $author ) ) {
            $author = $author[ 0 ];
            if ( $author->nickname ) {
                return $author->nickname;
            } else {
                return $author->name;
            }
        }
    }
}
?>