<?php
function smarty_function_mtbannertext ( $args, &$ctx ) {
    require_once( 'function.mtcampaigntext.php' );
    return smarty_function_mtcampaigntext( $args, $ctx );
}
?>