<?php
function smarty_block_mtifmemberlogin( $args, $content, &$ctx, &$repeat ) {
    $client_author = $ctx->stash( 'client_author' );
    $client_author_id = $ctx->stash( 'client_author_id' );
    if ( isset( $client_author ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        if ( $client_author_id ) {
            require_once( 'class.mt_author.php' );
            $_author = new Author;
            $where = " author_id = $author_id and author_status = 1";
            $extra = array(
                'limit' => 1,
            ); 
            $client_author = $_author->Find( $where, false, false, $extra );
            if ( isset( $client_author ) ) {
                $client_author = $client_author[ 0 ];
                $ctx->stash( 'client_author', $client_author );
                $ctx->stash( 'client_author_id', $client_author_id );
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            } else {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
            }
        } else {
            if ( isset( $_COOKIE[ 'mt_user' ] ) ) {
                $cookie = $_COOKIE[ 'mt_user' ];
                if ( preg_match( '/^(.*?)::(.*?)::.*$/', $cookie, $match ) ) {
                    $sess_id = $match[ 2 ];
                }
                $name = 'US';
            } else if ( isset( $_COOKIE[ 'mt_commenter' ] ) ) {
                $sess_id = $_COOKIE[ 'mt_commenter' ];
                $name = 'SI';
            } else if ( isset( $_COOKIE[ 'mt_blog_user' ] ) ) {
                $cookie = $_COOKIE[ 'mt_blog_user' ];
                if ( preg_match( "/sid:.'(.*?).'.*?$/", $cookie, $match ) ) {
                    $sess_id = $match[ 1 ];
                }
                $name = 'US';
            } else {
                $sess_id = $_REQUEST[ 'sessid' ];
                $name = 'US';
            }
            if ( $sess_id ) {
                $sql = "SELECT * FROM mt_session WHERE session_id ='{$sess_id}' and session_kind='{$name}'";
                $results = $ctx->mt->db()->Execute( $sql );
                if ( isset( $results ) ) {
                    $sess_obj = empty( $results ) ? NULL : $results;
                    $client_author = NULL;
                    $sess_data = $sess_obj->fields[ 'session_data' ];
                    if ( $sess_obj && $sess_data ) {
                        $data = $ctx->mt->db()->unserialize( $sess_data );
                        if ( $data ) {
                            $author_id = $data[ 'author_id' ];
                            if ( $author_id ) {
                                require_once( 'class.mt_author.php' );
                                $_author = new Author;
                                $where = " author_id = $author_id and author_status = 1";
                                $extra = array(
                                    'limit' => 1,
                                ); 
                                $client_author = $_author->Find( $where, false, false, $extra );
                                if ( isset ( $client_author ) ) {
                                    $blog_id = $ctx->stash( 'blog_id' );
                                    $client_author = $client_author[ 0 ];
                                    # Permission check
                                    require_once ( 'class.mt_permission.php' );
                                    $Permission = new Permission;
                                    $where = "permission_author_id = '{$author_id}'"
                                           . " and permission_blog_id = '{$blog_id}'"
                                           . " and permission_permissions LIKE \"%'view'%\"";
                                    $perms = $Permission->Find( $where );
                                    if (! isset( $perms ) ) {
                                        $where = "permission_author_id = '{$author_id}'"
                                           . " and ( permission_blog_id='{$blog_id}' OR permission_blog_id='0' )"
                                           . " and permission_permissions LIKE \"%'administer%\"";
                                        $perms = $Permission->Find( $where );
                                    }
                                    $ctx->stash( 'client_author', $client_author );
                                    $ctx->stash( 'client_author_id', $client_author_id );
                                    if ( isset( $perms ) ) {
                                        $ctx->stash( 'member_login', 1 );
                                        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
                                    } else {
                                        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>
