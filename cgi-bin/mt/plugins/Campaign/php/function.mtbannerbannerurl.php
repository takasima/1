<?php
function smarty_function_mtbannerbannerurl ( $args, &$ctx ) {
    require_once( 'function.mtcampaignbannerurl.php' );
    return smarty_function_mtcampaignbannerurl( $args, $ctx );
}
