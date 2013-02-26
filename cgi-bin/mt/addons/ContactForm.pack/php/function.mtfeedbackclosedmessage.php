<?php
function smarty_function_mtfeedbackclosedmessage ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $message = $contactformgroup->closed_message;
    require_once( 'modifier.mteval.php' );
    return smarty_modifier_mteval( $message, 1 );
}
?>