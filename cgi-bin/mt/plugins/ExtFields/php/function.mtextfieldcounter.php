<?php
function smarty_function_mtextfieldcounter ( $args, $ctx ) {
    $extfields_counter = $ctx->stash( '_extfields_counter' );
    if ( $extfields_counter ) {
        return $extfields_counter;
    } else {
        return 0;
    }
}
?>