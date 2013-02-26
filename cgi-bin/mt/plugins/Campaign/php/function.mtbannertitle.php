<?php
function smarty_function_mtbannertitle ( $args, &$ctx ) {
    require_once( 'function.mtcampaigntitle.php' );
    return smarty_function_mtcampaigntitle( $args, $ctx );
}
?>