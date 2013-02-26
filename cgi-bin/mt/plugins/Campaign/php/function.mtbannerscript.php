<?php
function smarty_function_mtbannerscript ( $args, &$ctx ) {
    require_once( 'function.mtcampaignscript.php' );
    return smarty_function_mtcampaignscript( $args, $ctx );
}
?>
