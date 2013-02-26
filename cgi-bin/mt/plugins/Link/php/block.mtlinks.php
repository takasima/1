<?php
function smarty_block_mtlinks( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'link', '_links_counter', 'links',
                        'blog', 'blog_id', 'include_blogs' );
    $app = $ctx->stash( 'bootstrapper' );
    $lastn  = $args[ 'lastn' ];
    $limit  = $args[ 'limit' ];
    if ( $lastn ) {
        $lastn = intval( $lastn );
    }
    if ( $limit ) {
        $limit = intval( $limit );
    }
    if ( isset ( $lastn ) ) {
        $limit = $lastn;
    }
    $offset = $args[ 'offset' ];
    if (! $offset ) {
        $offset = 0;
    } else {
        $offset = intval( $offset );
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
        $sort_by = 'id';
    }
    $link_status_suf = '';
    $link_status_pre = '';
    if (! $args[ 'include_draft' ] ) {
        $link_status_suf = 'link_status=2 AND';
        $link_status_pre = 'AND link_status=2';
    }
    $group   = $args[ 'group' ];
    $ids     = $args[ 'ids' ];
    $group = $ctx->mt->db()->escape( $group );
    $ids = $ctx->mt->db()->escape( $ids );
    $group_id = $args[ 'group_id' ];
    $tag_name = $args[ 'tag' ];
    $tag_name = $ctx->mt->db()->escape( $tag_name );
    $blog_id  = $args[ 'blog_id' ];
    $rating   = $args[ 'rating' ];
    $more     = $args[ 'more' ];
    $less     = $args[ 'less' ];
    if ( $blog_id ) {
        $blog_id = intval( $blog_id );
    }
    if ( $rating ) {
        $rating  = intval( $rating );
    }
    if ( $more ) {
        $more  = intval( $more );
    }
    if ( $less ) {
        $less  = intval( $less );
    }
    $url_active = $args[ 'url_active' ];
    $rss_active = $args[ 'rss_active' ];
    $image_active = $args[ 'image_active' ];
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    }
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        if ( $ctx->__stash[ 'links' ] ) {
            $ctx->__stash[ 'links' ] = NULL;
        }
        $counter = 0;
        //$include_blogs = include_exclude_blogs( $ctx, $args );
        $include_blogs = $app->include_exclude_blogs( $ctx, $args );
        $ctx->stash( 'include_blogs', $include_blogs );
    } else {
        $counter = $ctx->stash( '_links_counter' );
        $include_blogs = $ctx->stash( 'include_blogs' );
    }
    $links = $ctx->stash( 'links' );
    if (! isset( $links ) ) {
        require_once 'class.mt_link.php';
        if ( $group || $group_id ) {
//            require_once 'class.mt_linkgroup.php';
            include_once( 'link.util.php' );
            $group_prefix = __init_linkgroup_class( $ctx );
            if (! $group_id ) {
                $_sort = new LinkGroup;
                $sql = "{$group_prefix}_name = '{$group}' AND {$group_prefix}_blog_id = {$blog_id}";
                $results = $_sort->Find( $sql );
                if ( count( $results ) ) {
                    $group_id_column = "${group_prefix}_id";
                    $group_id = $results[0]->$group_id_column;
                }
                if (! $group_id ) {
                    $repeat = FALSE;
                    return '';
                }
            }
//            require_once 'class.mt_linkorder.php';
            $order_prefix = __init_linkorder_class( $ctx );
            $where = "{$order_prefix}_group_id={$group_id}"
                   . " ORDER BY {$order_prefix}_order {$sort_order}"
                   ;
            $extra[ 'join' ] = array(
                "mt_{$order_prefix}" => array(
                    'condition' => "{$order_prefix}_link_id=link_id",
                ),
            );
        } elseif ( $tag_name ) {
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
                    $where = " {$link_status_suf} objecttag_tag_id = {$tag_id}"
                           // . " AND objecttag_blog_id = {$blog_id}"
                           . " AND objecttag_object_datasource = 'link'"
                           . " ORDER BY link_{$sort_by} {$sort_order}"
                           ;
                    $extra[ 'join' ] = array(
                        'mt_objecttag' => array(
                            'condition' => 'link_id=objecttag_object_id',
                        ),
                    );
                }
            }
        } else {
            if ( $ids ) {
                $where = "link_id in ({$ids}) {$link_status_pre} ORDER BY link_{$sort_by} {$sort_order}";
            } else {
                $where = "link_blog_id {$include_blogs} {$link_status_pre} ORDER BY link_{$sort_by} {$sort_order}";
            }
        }
        if ( $limit ) {
            $extra[ 'limit' ] = $limit;
        }
        if ( $offset ) {
            $extra[ 'offset' ] = $offset;
        }
//        if ( $rating ) {
        if ( isset( $rating ) && $rating != '' ) {
            $where = "link_rating = {$rating} AND $where";
        } else {
            if ( $less ) {
                $less++;
                $where = "link_rating < {$less} AND $where";
            } else if ( $more ) {
                $more--;
                $where = "link_rating > {$more} AND $where";
            }
        }
        if ( $url_active ) {
            $where = "link_broken_link != 1 AND link_url != '' AND $where";
        }
        if ( $rss_active ) {
            $where = "link_broken_rss != 1 AND link_rss_address != '' AND $where";
        }
        if ( $image_active ) {
            $where = "link_broken_image != 1 AND link_image_address != '' AND $where";
        }
        $_link = new Link;
        $links = $_link->Find( $where, false, false, $extra );
        if ( count( $links ) == 0 ) {
            $links = array();
        }
        $ctx->stash( 'links', $links );
    } else {
        $counter = $ctx->stash( '_links_counter' );
    }
    if ( $counter < count( $links ) ) {
        $link = $links[ $counter ];
        $args[ 'blog_id' ] = $link->link_blog_id;
        $ctx->stash( 'link', $link );
        $ctx->stash( '_links_counter', $counter + 1 );
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $links ) );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>