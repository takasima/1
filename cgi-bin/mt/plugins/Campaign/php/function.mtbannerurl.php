<?php
function smarty_function_mtbannerurl ( $args, &$ctx ) {
    require_once( 'function.mtcampaignurl.php' );
    return smarty_function_mtcampaignurl( $args, $ctx );
}
?>