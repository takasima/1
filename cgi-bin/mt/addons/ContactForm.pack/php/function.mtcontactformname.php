<?php
function smarty_function_mtcontactformname ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    if ( $contactformgroup ) {
        return $contactformgroup->name;
    }
    return '';
}
?>