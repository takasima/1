<?php
function smarty_function_mtcampaignmaxclicks ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $max_clicks = $campaign->max_clicks;
        if ( $max_clicks ) {
            return $max_clicks;
        } else {
            return '0';
        }
    }
}
?>