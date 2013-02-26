<?php
function smarty_function_mtbannerauthordisplayname ( $args, &$ctx ) {
    require_once( 'function.mtcampaignauthordisplayname.php' );
    return smarty_function_mtcampaignauthordisplayname( $args, $ctx );
}
?>