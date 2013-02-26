<?php
function smarty_function_mtkeitaipagenumber ( $args, &$ctx ) {
    return $ctx->stash( "_list_counter" );
}
?>