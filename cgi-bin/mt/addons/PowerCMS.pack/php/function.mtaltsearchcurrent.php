<?php
function smarty_function_mtaltsearchcurrent ( $args, $ctx ) {
    return $ctx->stash( 'current' );
}
?>