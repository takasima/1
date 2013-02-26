<?php
function smarty_function_mtaltsearchdate ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $date = $app->param( 'date' );
    if ( ( $date == 'created_on' ) || ( $date == 'modified_on' ) ) {
    } else {
        $date = 'authored_on';
    }
    return $date;
}
?>