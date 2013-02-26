<?php
function smarty_function_mtmembersgetnickname ( $args, &$ctx ) {
    $plugin_data = $ctx->mt->db()->fetch_plugin_data( 'members', 'configuration' );

    $sess_timeout = $plugin_data[ 'members_session_timeout' ];

    if ( $sess_timeout == '' ) {
        $sess_timeout = 3600;
    }

    $sess_id = $_REQUEST[ 'sess_id' ];
    require_once 'class.mt_session.php';
    $_ses = new Session;
    $where = "session_id = '{$sess_id}' and session_kind = 'US'";
    $results = $_ses->Find($where);

    if ( count( $results ) ) {
        $sess_obj = empty( $results ) ? NULL : $results[ 0 ];
        $user_id = 0;
        $user    = NULL;

        if ( $sess_obj && $sess_obj->session_data && ( time() - $sess_obj->session_start ) < $sess_timeout ) {

            $data = $ctx->mt->db()->unserialize( $sess_obj->session_data );

            if ( $data ) {
                $author_id = $data['author_id'];

                if ( $author_id ) {
                    require_once 'class.mt_author.php';
                    $_author = new Author;
                    $where = "author_id = {$author_id}";
                    $results = $_author->Find($where);
                    return $author_name = $results[ 0 ]->author_nickname;
                }
            }
        }
    }
}
?>
