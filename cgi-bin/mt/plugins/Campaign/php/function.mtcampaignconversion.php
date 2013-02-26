<?php
function smarty_function_mtcampaignconversion ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $conversion = $campaign->conversion;
        if ( $conversion ) {
            return $conversion;
        } else {
            return '0';
        }
    }
}
?>