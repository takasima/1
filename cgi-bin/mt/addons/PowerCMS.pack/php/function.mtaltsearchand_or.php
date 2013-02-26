<?php
function smarty_function_mtaltsearchand_or ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $and_or = $app->param( 'and_or' );
    if ( ( $and_or == 'and' ) || ( $and_or == 'or' ) ) {
        return $and_or;
    }
}
?>