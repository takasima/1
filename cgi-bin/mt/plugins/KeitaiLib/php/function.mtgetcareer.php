<?php
function smarty_function_mtgetcareer ( $args, &$ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    return $app->get_agent();
}
?>