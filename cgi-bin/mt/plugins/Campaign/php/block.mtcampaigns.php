<?php
function smarty_block_mtcampaigns ( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'campaign', '_campaigns_counter', 'campaigns',
                        'blog', 'blog_id', 'include_blogs' );
    // $app = $ctx->stash( 'bootstrapper' );
    $active = $args[ 'active' ];
    $lastn  = $args[ 'lastn' ];
    $limit  = $args[ 'limit' ];
    if ( isset ( $lastn ) ) {
        $limit = $lastn;
    }
    $offset = $args[ 'offset' ];
    if (! isset ( $offset ) ) {
        $offset = 0;
    }
    $sort_order = $args[ 'sort_order' ];
    if ( $sort_order == 'descend' ) {
        $sort_order = 'DESC';
    } else {
        $sort_order = 'ASC';
    }
    if (! isset ( $limit ) ) {
        $limit = 9999;
    }
    $sort_by  = $args[ 'sort_by' ];
    if (! isset ( $sort_by ) ) {
        $sort_by = 'publishing_on';
    }
    $group = $args[ 'group' ];
    $group_id = $args[ 'group_id' ];
    $tag_name = $args[ 'tag' ];
    $blog_id = $args[ 'blog_id' ];
    $ids = $args[ 'ids' ];
    $campaign_status = '';
    if (! $args[ 'include_draft' ] ) {
        $campaign_status = 'AND campaign_status=2';
    }
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    } else {
        $blog    = $ctx->mt->db()->fetch_blog( $blog_id );
        $blog_id = $blog->id;
    }
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        if ( $ctx->__stash[ 'campaigns' ] ) {
            $ctx->__stash[ 'campaigns' ] = NULL;
        }
        $counter = 0;
        // $include_blogs = $app->include_blogs( $blog, $args );
        // $include_blogs = $app->include_exclude_blogs( $ctx, $args );
        $include_blogs = __campaign_include_exclude_blogs( $ctx, $args );
        $ctx->stash( 'include_blogs', $include_blogs );
    } else {
        $counter = $ctx->stash( '_campaigns_counter' );
        $include_blogs = $ctx->stash( 'include_blogs' );
    }
    $ctx->stash( 'blog_id', $blog_id );
    $ctx->stash( 'blog', $blog );
    $campaigns = $ctx->stash( 'campaigns' );
    if (! isset( $campaigns ) ) {
        $tssql = '';
        if ( isset( $active ) ) {
            $campaign_status = 'AND campaign_status=2';
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
        require_once 'class.mt_campaign.php';
        if ( $group || $group_id ) {
            include_once( 'campaign.util.php' );
            $group_prefix = __init_campaigngroup_class( $ctx );
            if (! $group_id ) {
                $_sort = new CampaignGroup;
                $where = "{$group_prefix}_name = '{$group}' AND {$group_prefix}_blog_id = {$blog_id}";
                $results = $_sort->Find( $where );
                if ( count( $results ) ) {
                    $group_id_column = "${group_prefix}_id";
                    $group_id = $results[0]->$group_id_column;
                }
            }
            if (! $group_id ) {
                $repeat = FALSE;
                return '';
            }
            $order_prefix = __init_campaignorder_class( $ctx );
            $where = NULL;
            if ( $tssql ) {
                $where = " $tssql AND ";
            }
            $where = " {$order_prefix}_group_id={$group_id}"
                   . " {$campaign_status}"
                   . " ORDER BY {$order_prefix}_order {$sort_order}"
                   ;
            $extra[ 'join' ] = array(
                "mt_{$order_prefix}" => array(
                    'condition' => "{$order_prefix}_campaign_id=campaign_id",
                ),
            );
        } else if ( isset ( $tag_name ) ) {
            require_once 'class.mt_tag.php';
            $_tag = new Tag;
//             $sql = "( tag_name = '{$tag_name}' ) AND ( binary( tag_name ) = '{$tag_name}' )";
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
                    $where = "campaign_blog_id {$include_blogs} $tssql AND objecttag_tag_id = {$tag_id}"
                           // . " AND objecttag_blog_id = {$blog_id}"
                           . " AND objecttag_object_datasource = 'campaign' {$campaign_status}"
                           . " ORDER BY campaign_{$sort_by} {$sort_order}"
                           ;
                    $extra[ 'join' ] = array(
                        'mt_objecttag' => array(
                            'condition' => 'campaign_id=objecttag_object_id',
                        ),
                    );
                }
            }
        } else {
            if ( $ids ) {
                $where = "campaign_id in ({$ids}) {$campaign_status} $tssql ORDER BY campaign_{$sort_by} {$sort_order}";
            } else {
                $where = "campaign_blog_id {$include_blogs} {$campaign_status} $tssql ORDER BY campaign_{$sort_by} {$sort_order}";
            }
        }
        if ( $limit ) {
            $extra[ 'limit' ] = $limit;
        }
        if ( $offset ) {
            $extra[ 'offset' ] = $offset;
        }
        $_campaign = new Campaign;
        $campaigns = $_campaign->Find( $where, false, false, $extra );
        if ( count( $campaigns ) == 0 ) {
            $campaigns = array();
        }
        $shuffle = $args[ 'shuffle' ];
        if ( $shuffle ) {
            shuffle( $campaigns );
        }
        $ctx->stash( 'campaigns', $campaigns );
    } else {
        $counter = $ctx->stash( '_campaigns_counter' );
    }
    if ( $counter < count( $campaigns ) ) {
        $campaign = $campaigns[ $counter ];
        $args[ 'blog_id' ] = $campaign->campaign_blog_id;
        $ctx->stash( 'campaign', $campaign );
        $ctx->stash( '_campaigns_counter', $counter + 1 );
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $campaigns ) );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
function __campaign_include_exclude_blogs ( $ctx, $args ) {
    if ( isset( $args[ 'blog_ids' ] ) ||
         isset( $args[ 'include_blogs' ] ) ||
         isset( $args[ 'include_websites' ] ) ) {
        $args[ 'blog_ids' ] and $args[ 'include_blogs' ] = $args[ 'blog_ids' ];
        $args[ 'include_websites' ] and $args[ 'include_blogs' ] = $args[ 'include_websites' ];
        $attr = $args[ 'include_blogs' ];
        unset( $args[ 'blog_ids' ] );
        unset( $args[ 'include_websites' ] );
        $is_excluded = 0;
    } elseif ( isset( $args[ 'exclude_blogs' ] ) ||
               isset( $args[ 'exclude_websites' ] ) ) {
        $attr = $args[ 'exclude_blogs' ];
        $attr or $attr = $args[ 'exclude_websites' ];
        $is_excluded = 1;
    } elseif ( isset( $args[ 'blog_id' ] ) && is_numeric( $args[ 'blog_id' ] ) ) {
        return ' = ' . $args[ 'blog_id' ];
    } else {
        $blog = $ctx->stash( 'blog' );
        if ( isset ( $blog ) ) return ' = ' . $blog->id;
    }
    if ( preg_match( '/-/', $attr ) ) {
        $list = preg_split( '/\s*,\s*/', $attr );
        $attr = '';
        foreach ( $list as $item ) {
            if ( preg_match('/(\d+)-(\d+)/', $item, $matches ) ) {
                for ( $i = $matches[1]; $i <= $matches[2]; $i++ ) {
                    if ( $attr != '' ) $attr .= ',';
                    $attr .= $i;
                }
            } else {
                if ( $attr != '' ) $attr .= ',';
                $attr .= $item;
            }
        }
    }
    $blog_ids = preg_split( '/\s*,\s*/', $attr, -1, PREG_SPLIT_NO_EMPTY );
    $sql = '';
    if ( $is_excluded ) {
        $sql = ' not in ( ' . join( ',', $blog_ids ) . ' )';
    } elseif ( $args[ include_blogs ] == 'all' ) {
        $sql = ' > 0 ';
    } elseif ( ( $args[ include_blogs ] == 'site' )
            || ( $args[ include_blogs ] == 'children' )
            || ( $args[ include_blogs ] == 'siblings' )
    ) {
        $blog = $ctx->stash( 'blog' );
        if (! empty( $blog ) && $blog->class == 'blog' ) {
            require_once( 'class.mt_blog.php' );
            $blog_class = new Blog();
            $blogs = $blog_class->Find( ' blog_parent_id = ' . $blog->parent_id );
            $blog_ids = array();
            foreach ( $blogs as $b ) {
                array_push( $ids, $b->id );
            }
            if ( $args[ 'include_with_website' ] )
                array_push( $blog_ids, $blog->parent_id );
            if ( count( $blog_ids ) ) {
                $sql = ' in ( ' . join( ',', $blog_ids ) . ' ) ';
            } else {
                $sql = ' > 0 ';
            }
        } else {
            $sql = ' > 0 ';
        }
    } else {
        if ( count( $blog_ids ) ) {
            $sql = ' in ( ' . join( ',', $blog_ids ) . ' ) ';
        } else {
            $sql = ' > 0 ';
        }
    }
    return $sql;
}
?>