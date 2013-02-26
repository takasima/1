<?php
function smarty_function_mtformelementname ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->name;
    }
    return '';
}
?>