<?php
function smarty_function_mtformelementoption ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->options;
    }
    return '';
}
?>