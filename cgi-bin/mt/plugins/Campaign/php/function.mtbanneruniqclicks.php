<?php
function smarty_function_mtbanneruniqclicks ( $args, &$ctx ) {
    require_once( 'function.mtcampaignuniqclicks.php' );
    return smarty_function_mtcampaignuniqclicks( $args, $ctx );
}
?>