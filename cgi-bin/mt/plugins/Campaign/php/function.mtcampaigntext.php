<?php
function smarty_function_mtcampaigntext ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        return $campaign->text;
    }
}
?>