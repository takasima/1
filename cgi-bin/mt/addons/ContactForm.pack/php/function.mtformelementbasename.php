<?php
function smarty_function_mtformelementbasename ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->basename;
    }
    return '';
}
?>