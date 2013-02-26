<?php
function smarty_function_mtcampaignconversionview ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $conversionview = $campaign->conversionview;
        if ( $conversionview ) {
            return $conversionview;
        } else {
            return '0';
        }
    }
}
?>