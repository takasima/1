<?php
function smarty_function_mtbannerpublishingon ( $args, &$ctx ) {
    require_once( 'function.mtcampaignpublishingon.php' );
    return smarty_function_mtcampaignpublishingon( $args, $ctx );
}
?>