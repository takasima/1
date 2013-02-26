<?php
function smarty_function_mtaltsearchpagecounter ( $args, $ctx ) {
    return $ctx->stash( '_altsearch_counter' );
}
?>