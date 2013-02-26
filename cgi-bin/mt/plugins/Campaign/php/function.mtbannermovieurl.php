<?php
function smarty_function_mtbannermovieurl ( $args, &$ctx ) {
    require_once( 'function.mtcampaignmovieurl.php' );
    return smarty_function_mtcampaignmovieurl( $args, $ctx );
}
?>