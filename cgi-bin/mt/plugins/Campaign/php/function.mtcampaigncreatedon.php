<?php
function smarty_function_mtcampaigncreatedon ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $args[ 'ts' ] = $campaign->created_on;
        return $ctx->_hdlr_date( $args, $ctx );
    }
}
?>