<?php
function smarty_function_mtbannerconversion ( $args, &$ctx ) {
    require_once( 'function.mtcampaignconversion.php' );
    return smarty_function_mtcampaignconversion( $args, $ctx );
}
?>