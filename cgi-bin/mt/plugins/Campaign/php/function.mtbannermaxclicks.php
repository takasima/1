<?php
function smarty_function_mtbannermaxclicks ( $args, &$ctx ) {
    require_once( 'function.mtcampaignmaxclicks.php' );
    return smarty_function_mtcampaignmaxclicks( $args, $ctx );
}
?>