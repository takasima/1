<?php
function smarty_function_mtbannerbannerwidth ( $args, &$ctx ) {
    require_once( 'function.mtcampaignbannerwidth.php' );
    return smarty_function_mtcampaignbannerwidth( $args, $ctx );
}
?>