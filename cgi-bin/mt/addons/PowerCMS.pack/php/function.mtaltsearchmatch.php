<?php
function smarty_function_mtaltsearchmatch ( $args, $ctx ) {
    return $ctx->stash( 'match' );
}
?>