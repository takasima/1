<?php
function smarty_function_mtformelementtype ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->type;
    }
    return '';
}
?>