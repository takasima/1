<?php
function smarty_function_mtbannermemo ( $args, &$ctx ) {
    require_once( 'function.mtcampaignmemo.php' );
    return smarty_function_mtcampaignmemo( $args, $ctx );
}
?>