<?php
function smarty_function_mtaltsearchresultpermalink ( $args, $ctx ) {
    $permalink = $ctx->stash( 'permalink' );
    if (! $permalink ) {
        return '';
    } else {
        return htmlspecialchars( $permalink );
    }
}
?>