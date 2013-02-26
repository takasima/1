<?php
function smarty_function_mtbannerperiodon ( $args, &$ctx ) {
    require_once( 'function.mtcampaignperiodon.php' );
    return smarty_function_mtcampaignperiodon( $args, $ctx );
}
?>