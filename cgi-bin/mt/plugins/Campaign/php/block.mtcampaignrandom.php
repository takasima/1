<?php
function smarty_block_mtcampaignrandom ( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'campaign' );
    $active  = $args[ 'active' ];
    $blog_id = $args[ 'blog_id' ];
    $group   = $args[ 'group' ];
    $tag_name = $args[ 'tag' ];
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    } else {
        $blog    = $ctx->mt->db()->fetch_blog( $blog_id );
        $blog_id = $blog->id;
    }
    require_once 'class.mt_campaign.php';
    $where = '';
    $tssql = '';
    if ( isset( $active ) ) {
        require_once( "MTUtil.php" );
        $t  = time();
        $ts = offset_time_list( $t, $ctx->stash( 'blog' ) );
        $ts = sprintf( "%04d%02d%02d%02d%02d%02d",
            $ts[5]+1900, $ts[4]+1, $ts[3], $ts[2], $ts[1], $ts[0] );
        $tssql .= " AND (";
        $tssql .= "   ( campaign_set_period = 1";
        $tssql .= "     AND campaign_publishing_on < '{$ts}'";
        $tssql .= "     AND campaign_period_on > '{$ts}'";
        $tssql .= "   ) OR (";
        $tssql .= "     campaign_set_period != 1";
        $tssql .= "   )";
        $tssql .= " )";
    }
    if ( isset ( $group ) ) {
//        require_once 'class.mt_campaigngroup.php';
        include_once( 'campaign.util.php' );
        $group_prefix = __init_campaigngroup_class( $ctx );
        $_sort = new CampaignGroup;
        $where = "{$group_prefix}_name='{$group}' AND {$group_prefix}_blog_id={$blog_id}";
        $results = $_sort->Find( $where );
        if ( count( $results ) ) {
            $group_id = $results[0]->id;
//            require_once 'class.mt_campaignorder.php';
            $order_prefix = __init_campaignorder_class( $ctx );
            $where = "campaign_blog_id={$blog_id} $tssql AND {$order_prefix}_group_id={$group_id}"
                   . " AND campaign_status=2"
                   . " ORDER BY {$order_prefix}_order {$sort_order}"
                   ;
            $extra[ 'join' ] = array(
                "mt_{$order_prefix}" => array(
                    'condition' => "{$order_prefix}_campaign_id=campaign_id",
                ),
            );
            $extra_sql = "{$order_prefix}_campaign_id=campaign_id";
        }
    } else if ( isset ( $tag_name ) ) {
        require_once 'class.mt_tag.php';
        $_tag = new Tag;
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $sql = "( tag_name = '{$tag_name}' ) AND ( tag_name = '{$tag_name}' )";
        } else {
            $sql = "( tag_name = '{$tag_name}' ) AND ( binary( tag_name ) = '{$tag_name}' )";
        }
        $results = $_tag->Find( $sql );
        if ( count( $results ) ) {
            $tag_id = $results[0]->tag_id;
            $sql = "( tag_id IN ( '{$tag_id}' ) )";
            $results = $_tag->Find( $sql );
            if ( count( $results ) ) {
                $tag_id = $results[0]->tag_id;
                $where = "campaign_blog_id = {$blog_id} $tssql AND objecttag_tag_id = {$tag_id}"
                       . " AND objecttag_blog_id = {$blog_id}"
                       . " AND objecttag_object_datasource = 'campaign' AND campaign_status = 2 "
                       ;
                $extra[ 'join' ] = array(
                    'mt_objecttag' => array(
                        'condition' => 'campaign_id=objecttag_object_id',
                    ),
                );
            }
        }
    } else {
        $where = "campaign_blog_id={$blog_id} AND campaign_status=2 $tssql";
    }
    $_campaign = new Campaign;
    $campaign = $_campaign->Find( $where, false, false, $extra );
    $count = count( $campaign );
    $counter = rand( 0, $count-1 );
    if ( isset( $campaign ) ) {
        $campaign = $campaign[ $counter ];
        $ctx->stash( 'campaign', $campaign );
    } else {
        return '';
    }
    return $content;
}
?>