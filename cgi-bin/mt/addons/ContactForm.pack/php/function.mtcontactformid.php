<?php
function smarty_function_mtcontactformid ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    if ( $contactformgroup ) {
        return $contactformgroup->id;
    }
    return '';
}
?>