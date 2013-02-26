<?php
function smarty_function_mtfeedbackerrormessage ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $message = $contactformgroup->error_message;
    require_once( 'modifier.mteval.php' );
    return smarty_modifier_mteval( $message, 1 );
}
?>