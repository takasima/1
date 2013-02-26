<?php
function smarty_function_mtcontactformscript ( $args, &$ctx ) {
    $contactformscript = $ctx->mt->config( 'ContactFormScript' );
    if (! $contactformscript ) {
        $contactformscript = 'mt-contactform.cgi';
    }
    return $contactformscript;

}
?>