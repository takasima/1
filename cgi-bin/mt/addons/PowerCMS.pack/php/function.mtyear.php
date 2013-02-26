<?php
function smarty_function_mtyear ( $args, $ctx ) {
    echo $ctx->stash( 'year' );
}
?>