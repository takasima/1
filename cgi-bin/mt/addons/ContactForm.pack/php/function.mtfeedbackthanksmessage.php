<?php
function smarty_function_mtfeedbackthanksmessage ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $message = $contactformgroup->message;
    require_once( 'modifier.mteval.php' );
    return smarty_modifier_mteval( $message, 1 );
}
?>