<?php
function smarty_function_mtcampaignperiodon ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $campaign->period_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>