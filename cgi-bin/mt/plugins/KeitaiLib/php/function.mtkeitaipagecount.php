<?php
function smarty_function_mtkeitaipagecount ( $args, &$ctx ) {
    return $ctx->stash( "_keitai_page_count" );
}
?>