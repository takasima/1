<?php
function smarty_function_mtformelementsize ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->size;
    }
    return '';
}
?>