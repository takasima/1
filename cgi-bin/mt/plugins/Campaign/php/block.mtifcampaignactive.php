<?php
function smarty_block_mtifcampaignactive ( $args, $content, &$ctx, &$repeat ) {
    if ( isset( $content ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    }
    if ( $campaign->status != 2 ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, false );
    }
    if ( $campaign->set_period != 1 ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, true );
    }
    $publishing_on = $campaign->publishing_on;
    $publishing_on = preg_replace( '/[\s:-]+/', '', $publishing_on );
    $period_on = $campaign->period_on;
    $period_on = preg_replace( '/[\s:-]+/', '', $period_on );
    require_once 'MTUtil.php';
    $t  = time();
    $ts = offset_time_list( $t, $ctx->stash( 'blog' ) );
    $ts = sprintf( '%04d%02d%02d%02d%02d%02d',
        $ts[5]+1900, $ts[4]+1, $ts[3], $ts[2], $ts[1], $ts[0] );
    if ( ( $ts > $publishing_on ) && ( $ts < $period_on ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, true );
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, false );
}
?>
