<?php
function smarty_function_mtextfieldlabel ( $args, $ctx ) {
    $extfield = $ctx->stash( 'extfield' );
    if ( $extfield ) {
        return $extfield->extfields_label;
    }
    return '';
}
?>