<?php
function smarty_block_mtgroupobjects( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'groupobject', '_groupobjects_counter', 'groupobjects',
                        'orig_groupobject', 'blog', 'blog_id', 'include_blogs' );
    // $app = $ctx->stash( 'bootstrapper' );
    $lastn = $args[ 'lastn' ];
    $limit = $args[ 'limit' ];
    if ( isset ( $lastn ) ) {
        $limit = $lastn;
    }
    $offset = $args[ 'offset' ];
    if ( ! isset( $offset ) ) {
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
    $sort_by = $args[ 'sort_by' ];
    if (! isset ( $sort_by ) ) {
        $sort_by = 'id';
    }
    $group = $args[ 'group' ];
    $group_id = $args[ 'group_id' ];
    $tag_name = $args[ 'tag' ];
    $blog_id = $args[ 'blog_id' ];
    $child_class = $args[ 'child_class' ];
    $class = $args[ 'class' ];
    if (! $class ) {
        $class = 'groupobject';
    }
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    }
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $ctx->stash( 'orig_groupobject', $ctx->stash( $args[ 'stash' ] ) );
        if ( $ctx->__stash[ 'groupobjects' ] ) {
            $ctx->__stash[ 'groupobjects' ] = NULL;
        }
        $counter = 0;
        // $include_blogs = include_blogs( $blog, $args );
        // $include_blogs = $app->include_exclude_blogs( $ctx, $args );
        $include_blogs = __customgroup_include_exclude_blogs( $ctx, $args );
        $ctx->stash( 'include_blogs', $include_blogs );
        // $include_blogs = $ctx->stash( 'include_blogs' ); # TODO
    } else {
        $counter = $ctx->stash( '_groupobjects_counter' );
        $include_blogs = $ctx->stash( 'include_blogs' );
    }
    $groupobjects = $ctx->stash( 'groupobjects' );
    if (! isset( $groupobjects ) ) {
        $prefix = $args[ 'prefix' ];
        $child_class = $args[ 'child_class' ];
        require_once( 'class.mt_' . $child_class . '.php' );
        $object = ucwords( $args[ 'child_class' ] );
        $_groupobject = new $object;
        $include_draft = '';
        if (! $args[ 'include_draft' ] ) {
            if ( $_groupobject->has_column( 'status' ) ) {
                $include_draft = " AND {$prefix}_status = 2 ";
            }
        }
        $include_class = '';
        $search_class = $args[ 'search_class' ];
        if ( is_array( $search_class ) ) {
            foreach ( $search_class as $this_class ) {
                if ( $include_class ) $include_class .= ' OR ';
                $include_class .= " {$prefix}_class = '{$this_class}' ";
            }
            $include_class = " AND ( {$include_class} )";
        }
        if ( ( isset ( $group ) ) || ( isset ( $group_id ) ) ) {
            if (! $group_id ) {
                include_once( 'customgroup.util.php' );
                $group_prefix = __init_customgroup_class( $ctx );
//                $group_prefix = 'customgroup';
//                require_once( 'class.mt_customgroup.php' );
                $_sort = new CustomGroup;
//                $where = "{$group_prefix}_name = '{$group}' AND {$group_prefix}_blog_id = {$blog_id} AND {$group_prefix}_class = '{$class}'";
                $where = "{$group_prefix}_name = '{$group}' ";
                if ( $class == 'websitegroup' ) {
                    $where .= "AND {$group_prefix}_blog_id = 0 ";
                } else {
                    $where .= "AND {$group_prefix}_blog_id = {$blog_id} ";
                }
                $where .= "AND {$group_prefix}_class = '{$class}'";
                $results = $_sort->Find( $where );
                if ( count( $results ) ) {
//                    $group_id = $results[0]->customgroup_id;
                    $group_id = $results[0]->id;
                }
            }
            if (! $group_id ) {
                $repeat = FALSE;
                return '';
            }
            require_once( 'class.mt_grouporder.php' );
            if ( $group_id ) {
                $order_prefix = 'grouporder';
//                 $where = "{$prefix}_blog_id {$include_blogs} {$include_class} {$include_draft} AND {$order_prefix}_group_id={$group_id}"
//                        . " ORDER BY {$order_prefix}_order {$sort_order}"
//                        ;
                $where = "1=1 {$include_class} {$include_draft} AND {$order_prefix}_group_id={$group_id}"
                       . " ORDER BY {$order_prefix}_order {$sort_order}"
                       ;
                $extra[ 'join' ] = array(
                    "mt_{$order_prefix}" => array(
                        'condition' => "{$order_prefix}_object_id={$prefix}_id",
                    ),
                );
            }
        } elseif ( isset ( $tag_name ) ) {
            require_once 'class.mt_tag.php';
            $_tag = new Tag;
// for Oracle
//            $sql = "( tag_name = '{$tag_name}' ) AND ( binary( tag_name ) = '{$tag_name}' )";
            $driver = strtolower( get_class( $ctx->mt->db() ) );
            $oracle = strpos( $driver, 'oracle' );
            if ( $oracle ) {        
                $sql = "( tag_name = '{$tag_name}' ) AND ( tag_name = '{$tag_name}' )";
            } else {
                $sql = "( tag_name = '{$tag_name}' ) AND ( binary( tag_name ) = '{$tag_name}' )";
            }
// /for Oracle
            $results = $_tag->Find( $sql );
            if ( count( $results ) ) {
                $tag_id = $results[0]->tag_id;
                $sql = "( tag_id IN ( '{$tag_id}' ) )";
                $results = $_tag->Find( $sql );
                if ( count( $results ) ) {
                    $tag_id = $results[0]->tag_id;
                    $where = "{$prefix}_blog_id {$include_blogs} {$include_class} {$include_draft} AND objecttag_tag_id = {$tag_id}"
                           // . " AND objecttag_blog_id = {$blog_id}"
                           . " AND objecttag_object_datasource = '{$prefix}'"
                           . " ORDER BY {$prefix}_{$sort_by} {$sort_order}"
                           ;
                    $extra[ 'join' ] = array(
                        'mt_objecttag' => array(
                            'condition' => "{$prefix}_id=objecttag_object_id",
                        ),
                    );
                }
            }
        } else {
            $ids = $args[ 'ids' ];
            if ( $ids ) {
                $ids = preg_replace( '/^,/', '', $ids );
                $ids = preg_replace( '/,$/', '', $ids );
                $where = " {$prefix}_id IN ( {$ids} ) {$include_draft}";
            } else {
                if ( $include_class ) {
                    $where = "{$prefix}_blog_id {$include_blogs} AND {$include_class} {$include_draft} ORDER BY {$prefix}_{$sort_by} {$sort_order}";
                    // FIXME: $include_class has two 'AND'
                    $where = str_replace( 'AND  AND', 'AND ', $where );
                } else {
                    $where = "{$prefix}_blog_id {$include_blogs} AND {$prefix}_class = '{$child_class}' {$include_draft} ORDER BY {$prefix}_{$sort_by} {$sort_order}";
                    if ( $prefix == 'blog' ) {
                        $where = "{$prefix}_class = '{$child_class}' {$include_draft} ORDER BY {$prefix}_{$sort_by} {$sort_order}";
                        # FIXME: in case of no 'group' or 'group_id' modifiers, following should be better process...
                        $where = preg_replace( "/^\s+\>\s+[0-9]{1,}\s+AND\s+/", '', $where );
                    } else {
                        $where = "{$prefix}_blog_id {$include_blogs} AND {$prefix}_class = '{$child_class}' {$include_draft} ORDER BY {$prefix}_{$sort_by} {$sort_order}";                    
                    }
                }
            }
        }
        if ( $limit ) {
            $extra[ 'limit' ] = $limit;
        }
        if ( $offset ) {
            $extra[ 'offset' ] = $offset;
        }
        // $object = ucwords( $prefix );
        // $_groupobject = new $object;
        $groupobjects = $_groupobject->Find( $where, FALSE, FALSE, $extra );
        $count = $args[ 'count' ];
        if ( isset( $count ) ) {
            return count( $groupobjects );
            $repeat = FALSE;
        }
        if ( count( $groupobjects ) == 0 ) {
            $groupobjects = array();
            $repeat = FALSE;
            return '';
        }
        $ctx->stash( 'groupobjects', $groupobjects );
    } else {
        $counter = $ctx->stash( '_groupobjects_counter' );
    }
    if ( $counter < count( $groupobjects ) ) {
        $groupobject = $groupobjects[ $counter ];
        if ( is_object( $groupobject ) ) {
            if ( $groupobject->has_column( 'blog_id' ) ) {
                $local_blog_id = $groupobject->blog_id;
                $ctx->stash( 'blog', $ctx->mt->db()->fetch_blog( $local_blog_id ) );
                $ctx->stash( 'blog_id', $local_blog_id );
            }
        }
        $ctx->stash( $args[ 'stash' ], $groupobject );
        $ctx->stash( 'customgroup_id', $group_id );
        $ctx->stash( 'customgroup_class', $class );
        $ctx->stash( '____stash', $args[ 'stash' ] );
        $ctx->stash( '_groupobjects_counter', $counter + 1 );
        if ( $count != 1 ) {
            $ctx->stash( 'previousobject', $groupobjects[ $counter - 1 ] );
        }
        if ( $count != count( $groupobjects ) ) {
            $ctx->stash( 'nextobject', $groupobjects[ $counter + 1 ] );
        }
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $groupobjects ) );
        $repeat = TRUE;
    } else {
        $orig_groupobject = $ctx->stash( 'orig_groupobject' );
        $ctx->restore( $localvars );
        $ctx->stash( $args[ 'stash' ], $orig_groupobject );
        $repeat = FALSE;
    }
    return $content;
}
function __customgroup_include_exclude_blogs ( $ctx, $args ) {
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