<?php
function smarty_function_mtcontactformauthordisplayname ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactformgroup' );
    if (! isset( $contactform ) ) {
        return $ctx->error();
    } else {
        $author_id = $contactform->author_id;
        require_once( 'class.mt_author.php' );
        $_author = new Author;
//        $where = " author_id = $author_id and author_status = 1";
        $where = " author_id = $author_id";
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