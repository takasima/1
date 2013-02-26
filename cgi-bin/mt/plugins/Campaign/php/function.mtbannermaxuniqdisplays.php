<?php
function smarty_function_mtbannermaxuniqdisplays ( $args, &$ctx ) {
    require_once( 'function.mtcampaignmaxuniqdisplays.php' );
    return smarty_function_mtcampaignmaxuniqdisplays( $args, $ctx );
}
?>