<?php
function smarty_function_mtbannerredirect ( $args, &$ctx ) {
    require_once( 'function.mtcampaignredirect.php' );
    return smarty_function_mtcampaignredirect( $args, $ctx );
}
?>