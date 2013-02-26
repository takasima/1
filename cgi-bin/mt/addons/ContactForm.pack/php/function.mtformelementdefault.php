<?php
function smarty_function_mtformelementdefault ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->default;
    }
    return '';
}
?>