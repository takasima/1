<?php
function smarty_function_mtfeedbackpreopenmessage ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $message = $contactformgroup->preopen_message;
    require_once( 'modifier.mteval.php' );
    return smarty_modifier_mteval( $message, 1 );
}
?>