<?php
function smarty_function_mtcampaignuniqclicks ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $uniqclicks = $campaign->uniqclicks;
        if ( $uniqclicks ) {
            return $uniqclicks;
        } else {
            return '0';
        }
    }
}
?>