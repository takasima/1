<?php
function smarty_function_mtbannerbannerheight ( $args, &$ctx ) {
    require_once( 'function.mtcampaignbannerheight.php' );
    return smarty_function_mtcampaignbannerheight( $args, $ctx );
}
?>