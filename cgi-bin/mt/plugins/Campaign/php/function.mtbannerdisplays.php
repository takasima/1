<?php
function smarty_function_mtbannerdisplays ( $args, &$ctx ) {
    require_once( 'function.mtcampaigndisplays.php' );
    return smarty_function_mtcampaigndisplays( $args, $ctx );
}
?>