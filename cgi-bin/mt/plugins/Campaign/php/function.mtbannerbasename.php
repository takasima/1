<?php
function smarty_function_mtbannerbasename ( $args, &$ctx ) {
    require_once( 'function.mtcampaignbasename.php' );
    return smarty_function_mtcampaignbasename( $args, $ctx );
}
?>