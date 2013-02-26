<?php
function smarty_function_mtestraierscript ( $args, &$ctx ) {
    $estraierscript = $ctx->mt->config( 'EstraierScript' );
    if ( ! $estraierscript ) {
        $estraierscript = 'mt-estraier.cgi';
    }
    return $estraierscript;
}
?>
