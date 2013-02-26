<?php
function smarty_function_mtcampaigndisplays ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $displays = $campaign->displays;
        if ( $displays ) {
            return $displays;
        } else {
            return '0';
        }
    }
}
?>