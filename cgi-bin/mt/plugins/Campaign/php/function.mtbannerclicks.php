<?php
function smarty_function_mtbannerlicks ( $args, &$ctx ) {
    require_once( 'function.mtcampaignclicks.php' );
    return smarty_function_mtcampaignclicks( $args, $ctx );
}
?>