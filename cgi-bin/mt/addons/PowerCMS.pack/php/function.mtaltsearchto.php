<?php
function smarty_function_mtaltsearchto ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $to = $app->param( 'to' );
    if ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $to ) ) {
        return $to;
    } else {
        return '';
    }
}
?>