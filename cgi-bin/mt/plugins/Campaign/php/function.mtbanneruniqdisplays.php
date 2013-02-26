<?php
function smarty_function_mtbanneruniqdisplays ( $args, &$ctx ) {
    require_once( 'function.mtcampaignuniqdisplays.php' );
    return smarty_function_mtcampaignuniqdisplays( $args, $ctx );
}
?>