<?php
function smarty_block_mtuserisnotmember($args, $content, &$ctx, &$repeat) {

    $blog = $ctx->stash('blog');
//    if ($blog->theme_id != "mt_powercms_members_blog") {
//        return;
//    }

    $plugin_data = $ctx->mt->db()->fetch_plugin_data( 'members', 'configuration' );
    $sess_timeout = $plugin_data[ 'members_session_timeout' ];
    if ( $sess_timeout == '' ) {
        $sess_timeout = 3600;
    }
    $blog_id = $_REQUEST[ 'blog_id' ];
    $sess_id = $_REQUEST[ 'sess_id' ];

    require_once 'class.mt_session.php';
    $_ses = new Session;
    $where = "session_id = '{$sess_id}' and session_kind = 'US'";
    $results = $_ses->Find($where);

    if ( count( $results ) ) {
        $sess_obj = empty( $results ) ? NULL : $results[ 0 ];
        $user_id = 0;
        $user = NULL;
        if ( $sess_obj && $sess_obj->session_data && ( time() - $sess_obj->session_start ) < $sess_timeout ) {

            $data = $ctx->mt->db()->unserialize( $sess_obj->session_data );

            if ( $data ) {
                $author_id = $data[ 'author_id' ];
                if ( $author_id ) {
                    require_once 'class.mt_permission.php';
                    $_perm = new Permission;
                    $where = "permission_author_id = '{$author_id}'"
                           . " AND permission_blog_id = '{$blog_id}'";
                    $results = $_perm->Find($where);

                    if( ! empty( $results ) ) {
                        return '';
                    }
                }
            }
        }
    }
    return $content;
}
?>
