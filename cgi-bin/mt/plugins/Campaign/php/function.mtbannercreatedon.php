<?php
function smarty_function_mtbannercreatedon ( $args, &$ctx ) {
    require_once( 'function.mtcampaigncreatedon.php' );
    return smarty_function_mtcampaigncreatedon( $args, $ctx );
}
?>