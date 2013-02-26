<?php
function smarty_function_mtaltsearchoffset ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $offset = $app->param( 'offset' );
    $offset = intval( $offset );
    if ( preg_match( "/^[0-9]+$/", $offset ) ) {
        if ( $offset == 0 ) {
            $offset = 1;
        }
    } else {
        $offset = 1;
    }
    return htmlspecialchars( $offset );
}
?>