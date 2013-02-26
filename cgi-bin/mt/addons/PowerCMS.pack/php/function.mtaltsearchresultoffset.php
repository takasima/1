<?php
function smarty_function_mtaltsearchresultoffset ( $args, $ctx ) {
    $counter = $ctx->stash( '_altsearch_counter' );
    $limit   = $ctx->stash( 'limit' );
    $offset  = $ctx->stash( 'offset' ); 
    return ( $limit * ( $counter - 1 ) ) + 1;
}
?>