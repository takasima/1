<?php
function smarty_function_mtformelementdescription ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    if ( $contactform ) {
        return $contactform->description;
    }
    return '';
}
?>