<?php
function smarty_function_mtbannerid ( $args, &$ctx ) {
    require_once( 'function.mtcampaignid.php' );
    return smarty_function_mtcampaignid( $args, $ctx );
}
?>