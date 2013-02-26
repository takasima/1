<?php
function smarty_function_mtextfieldvalue ( $args, $ctx ) {
    $value = $ctx->stash( 'value' );
    if ( $value ) {
        return $value;
    }
    return '';
}
?>