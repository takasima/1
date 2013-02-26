<?php
function smarty_function_mtcampaignmaxuniqdisplays ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $max_displays = $campaign->max_uniqdisplays;
        if ( $max_displays ) {
            return $max_displays;
        } else {
            return '0';
        }
    }
}
?>