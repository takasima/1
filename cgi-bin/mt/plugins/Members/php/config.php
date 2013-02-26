<?php
class Members extends MTPlugin {

    var $registry = array(
        'name' => 'Members',
        'id'   => 'Members',
        'key'  => 'members',
        'version' => '1.5',
        'author_name' => 'Alfasado Inc.',
        'author_link' => 'http://alfasado.net/',
        'callbacks' => array(
            'post_init' => 'post_init'
        ),
        'config_settings' => array(
            'MemberScript' => array( 'default' => 'mt-members.cgi' ),
        ),
    );

    function post_init( $mt, $ctx, &$args ) {
        $app = $ctx->stash( 'bootstrapper' );
        $type_text = $app->type_text( $args[ 'contenttype' ] );
        if (! $type_text ) {
            $blog = $ctx->stash( 'blog' );
            if ( $blog->is_members ) {
                if (! $app->user() ) {
                    $login_url = $app->config( 'CGIPath' );
                    if ( substr( $login_url, strlen( $login_url ) - 1, 1 ) !== '/' )
                        $login_url .= '/';
                    if ( preg_match( '!^(?:https?://[^/]+)?(/.*)$!', $login_url, $matches ) ) {
                        $login_url = $matches[ 1 ];
                    }
                    $login_url .= $app->config( 'MemberScript' );
                    $login_url.= '?__mode=login&blog_id=' . $blog->id;
                    $login_url.= '&return_url=' . rawurlencode( $args[ 'url' ] );
                    $app->redirect( $login_url );
                }
            }
        }
    }

}

?>
