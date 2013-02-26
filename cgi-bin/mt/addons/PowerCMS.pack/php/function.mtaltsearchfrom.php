<?php
function smarty_function_mtaltsearchfrom ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $from = $app->param( 'from' );
    if ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $from ) ) {
        return $from;
    } else {
        return '';
    }
}
?>