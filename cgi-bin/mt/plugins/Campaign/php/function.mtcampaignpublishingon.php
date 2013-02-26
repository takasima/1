<?php
function smarty_function_mtcampaignpublishingon ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $campaign->publishing_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>