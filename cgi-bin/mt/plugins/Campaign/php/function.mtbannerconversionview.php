<?php
function smarty_function_mtbannerconversionview ( $args, &$ctx ) {
    require_once( 'function.mtcampaignconversionview.php' );
    return smarty_function_mtcampaignconversionview( $args, $ctx );
}
?>