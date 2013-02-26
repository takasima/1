<?php
function smarty_function_mtbannerconversioncounter ( $args, &$ctx ) {
    require_once( 'function.mtcampaignconversioncounter.php' );
    return smarty_function_mtcampaignconversioncounter( $args, $ctx );
}
?>