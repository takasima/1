<?php
function smarty_function_mtcampaignclicks ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $clicks = $campaign->clicks;
        if ( $clicks ) {
            return $clicks;
        } else {
            return '0';
        }
    }
}
?>