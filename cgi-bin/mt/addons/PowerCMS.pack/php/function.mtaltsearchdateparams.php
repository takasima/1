<?php
function smarty_function_mtaltsearchdateparams ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $from = $app->param( 'from' );
    $to   = $app->param( 'to' );
    if ( ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $from ) ) ||
         ( preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $to ) ) ) {
        $date_params = "from=$from&to=$to";
    } else {
        $from_y = $app->param( 'from_y' );
        $from_m = $app->param( 'from_m' );
        $from_d = $app->param( 'from_d' );
        $to_y = $app->param( 'to_y' );
        $to_m = $app->param( 'to_m' );
        $to_d = $app->param( 'to_d' );
        $date_params = "from_y=$from_y&from_m=$from_m&from_d=$from_d&to_y=$to_y&to_m=$to_m&to_d=$to_d";
    }
    return htmlspecialchars( $date_params );
}
//from_y=2004&from_m=08&from_d=21&to_y=2008&to_m=01&to_d=25
?>