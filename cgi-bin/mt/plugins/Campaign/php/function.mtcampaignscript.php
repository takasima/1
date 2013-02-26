<?php
function smarty_function_mtcampaignscript ( $args, &$ctx ) {
    $campaignscript = $ctx->mt->config( 'BannerScript' );
    if (! $campaignscript ) {
        $campaignscript = $ctx->mt->config( 'CampaignScript' );
    }
    if (! $campaignscript ) {
        $campaignscript = 'mt-banner.cgi';
    }
    return $campaignscript;
}
?>
