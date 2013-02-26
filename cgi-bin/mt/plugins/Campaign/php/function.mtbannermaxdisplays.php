<?php
function smarty_function_mtbannermaxdisplays ( $args, &$ctx ) {
    require_once( 'function.mtcampaignmaxdisplays.php' );
    return smarty_function_mtcampaignmaxdisplays( $args, $ctx );
}
?>