<?php
function smarty_function_mtcampaignuniqdisplays ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $uniqdisplays = $campaign->uniqdisplays;
        if ( $uniqdisplays ) {
            return $uniqdisplays;
        } else {
            return '0';
        }
    }
}
?>