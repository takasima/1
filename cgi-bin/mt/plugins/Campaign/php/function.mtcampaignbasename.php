<?php
function smarty_function_mtcampaignbasename ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        return $campaign->basename;
    }
}
?>