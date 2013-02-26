<?php
function smarty_function_mtcampaignid ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        return $campaign->id;
    }
}
?>