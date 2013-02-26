<?php
function smarty_function_mtcampaignmemo ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        return $campaign->memo;
    }
}
?>