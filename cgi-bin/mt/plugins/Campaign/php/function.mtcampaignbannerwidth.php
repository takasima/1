<?php
function smarty_function_mtcampaignbannerwidth ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        require_once( "function.mtcampaignbannerurl.php" );
        $image = get_campaign_image( $args, $ctx, $campaign );
        return $image[1];
    }
}
?>