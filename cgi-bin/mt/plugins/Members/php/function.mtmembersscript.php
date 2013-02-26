<?php
function smarty_function_mtmembersscript ( $args, &$ctx ) {
    $memberscript = $ctx->mt->config( 'MemberScript' );
    if ( ! $memberscript ) {
        $memberscript = 'mt-members.cgi';
    }
    return $memberscript;
}
?>
