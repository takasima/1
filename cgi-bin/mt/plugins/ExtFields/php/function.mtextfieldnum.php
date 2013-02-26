<?php
function smarty_function_mtextfieldnum ( $args, $ctx ) {
    return $ctx->stash( '_extfields_counter' );
}
?>