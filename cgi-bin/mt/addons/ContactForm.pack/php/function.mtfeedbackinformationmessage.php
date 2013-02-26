<?php
function smarty_function_mtfeedbackinformationmessage ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $message = $contactformgroup->information_message;
    require_once( 'modifier.mteval.php' );
    return smarty_modifier_mteval( $message, 1 );
}
?>