<?php
function smarty_function_mtbannercounter ( $args, &$ctx ) {
    require_once( 'function.mtcampaigncounter.php' );
    return smarty_function_mtcampaigncounter( $args, $ctx );
}
?>