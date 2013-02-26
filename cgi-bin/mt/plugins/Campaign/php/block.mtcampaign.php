<?php
function smarty_block_mtcampaign ( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'campaign' );
    $active = $args[ 'active' ];
    $basename = $args[ 'basename' ];
    $title = $args[ 'title' ];
    $identifier = $args[ 'identifier' ];
    if (isset ( $identifier ) ) {
        $basename = $identifier;
    }
    $id = $args[ 'id' ];
    $campaign_status = '';
    if (! $args[ 'include_draft' ] ) {
        $campaign_status = 'campaign_status=2';
    }
    $blog_id = $args[ 'blog_id' ];
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    } else {
        $blog    = $ctx->mt->db()->fetch_blog( $blog_id );
        $blog_id = $blog->id;
    }
    require_once 'class.mt_campaign.php';
    if (! isset( $id ) ) {
        $where = "campaign_blog_id={$blog_id} AND {$campaign_status}";
    } else {
        $where = $campaign_status;
    }
    if ( isset( $basename ) ) {
        $where .= " AND campaign_basename='{$basename}'";
    }
    if ( isset( $title ) ) {
        $where .= " AND campaign_title='{$title}'";
    }
    if ( isset( $id ) ) {
        $where .= " AND campaign_id={$id}";
    }
    if ( isset( $active ) ) {
        $campaign_status = 'campaign_status=2';
        require_once 'MTUtil.php';
        $t  = time();
        $ts = offset_time_list( $t, $ctx->stash( 'blog' ) );
        $ts = sprintf( '%04d%02d%02d%02d%02d%02d',
            $ts[5]+1900, $ts[4]+1, $ts[3], $ts[2], $ts[1], $ts[0] );
        $where .= " AND (";
        $where .= "   ( campaign_set_period = 1";
        $where .= "     AND campaign_publishing_on < '{$ts}'";
        $where .= "     AND campaign_period_on > '{$ts}'";
        $where .= "   ) OR (";
        $where .= "     campaign_set_period != 1";
        $where .= "   )";
        $where .= " )";
    }
    $extra[ 'limit' ] = 1;
    $_campaign = new Campaign;
    $campaign = $_campaign->Find( $where, FALSE, FALSE, $extra );
    if ( isset( $campaign ) ) {
        $campaign = $campaign[0];
        $ctx->stash( 'campaign', $campaign );
    } else {
        $ctx->restore( $localvars );
        $repeat = FALSE;
        //exit();
    }
    return $content;
}
?>