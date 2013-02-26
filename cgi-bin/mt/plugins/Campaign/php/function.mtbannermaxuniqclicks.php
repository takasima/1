<?php
function smarty_function_mtbannermaxuniqclicks ( $args, &$ctx ) {
    require_once( 'function.mtcampaignmaxuniqclicks.php' );
    return smarty_function_mtcampaignmaxuniqclicks( $args, $ctx );
}
?>