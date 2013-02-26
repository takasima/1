<?php
function smarty_block_mtifaltsearchdate ( $args, $content, $ctx, $repeat ) {
    $app = $ctx->stash( 'bootstrapper' );
    $from_y = $app->param( 'from_y' );
    $from_m = $app->param( 'from_m' );
    $from_d = $app->param( 'from_d' );
    $to_y = $app->param( 'to_y' );
    $to_m = $app->param( 'to_m' );
    $to_d = $app->param( 'to_d' );
    $to_d = $app->param( 'to_d' );
    if ( $from_y ) {
        $from = "$from_y-$from_m-$from_d";
    }
    if ( $to_y ) {
        $to = "$to_y-$to_m-$to_d";
    }
    if ( $app->param( 'from' ) ) {
        $from = $app->param( 'from' );
    }
    if ( $app->param( 'to' ) ) {
        $to = $app->param( 'to' );
    }
    if ( ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $from ) ) ||
         ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $to ) ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>