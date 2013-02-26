<?php
function smarty_function_mtaltsearchresultnumber ( $args, $ctx ) {
    return $ctx->stash( '_entries_counter' );
}
?>