<?php
function smarty_block_mtcustomobjects( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'customobject', '_customobjects_counter', 'customobjects',
                        'blog', 'blog_id', 'include_blogs' );
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
    $class = $args[ 'class' ];
    if (! $class ) {
        $class = 'customobject';
    }
    if ( $blog_id == '' ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog    = $ctx->stash( 'blog' );
    }
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        if ( $ctx->__stash[ 'customobjects' ] ) {
            $ctx->__stash[ 'customobjects' ] = NULL;
        }
        $counter = 0;
        // $include_blogs = include_blogs( $blog, $args );
        // $include_blogs = $app->include_exclude_blogs( $ctx, $args );
        $include_blogs = __include_exclude_blogs( $ctx, $args );
        $ctx->stash( 'include_blogs', $include_blogs );
        // $include_blogs = $ctx->stash( 'include_blogs' ); # TODO
    } else {
        $counter = $ctx->stash( '_customobjects_counter' );
        $include_blogs = $ctx->stash( 'include_blogs' );
    }
    $customobjects = $ctx->stash( 'customobjects' );
    if (! isset( $customobjects ) ) {
        include_once( 'customobject.util.php' );
        $prefix = __init_customobject_class ( $ctx );
        $include_draft = '';
        if (! $args[ 'include_draft' ] ) {
            $include_draft = " AND {$prefix}_status = 2 ";
        }
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( ( isset ( $group ) ) || ( isset ( $group_id ) ) ) {
            if (! $group_id ) {
                $group_prefix = __init_customobjectgroup_class ( $ctx );
                $_sort = new CustomObjectGroup;
                $where = "{$group_prefix}_name = '{$group}' AND {$group_prefix}_blog_id = {$blog_id} AND {$group_prefix}_class = '{$class}group'";
                $results = $_sort->Find( $where );
                if ( count( $results ) ) {
                    if ( $oracle ) {
                        $group_id = $results[0]->cog_id;
                    } else {
                        $group_id = $results[0]->customobjectgroup_id;
                    }
                }
            }
            if (! $group_id ) {
                $ctx->restore( $localvars );
                $repeat = FALSE;
                return '';
            }
            if ( $group_id ) {
                $order_prefix = __init_customobjectorder_class ( $ctx );
                $where = " {$order_prefix}_group_id={$group_id} {$include_draft}"
                       . " ORDER BY {$order_prefix}_order {$sort_order}"
                       ;
                $extra[ 'join' ] = array(
                    "mt_{$order_prefix}" => array(
                        'condition' => "{$order_prefix}_customobject_id={$prefix}_id",
                    ),
                );
            }
        } elseif ( isset ( $tag_name ) ) {
            require_once 'class.mt_tag.php';
            $_tag = new Tag;
// for Oracle
//            $sql = "( tag_name = '{$tag_name}' ) AND ( binary( tag_name ) = '{$tag_name}' )";
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
                    $where = "{$prefix}_blog_id {$include_blogs} {$include_draft} AND objecttag_tag_id = {$tag_id}"
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
            } else {
                $ctx->restore( $localvars );
                $repeat = FALSE;
                return '';
            }
        } else {
            $ids = $args[ 'ids' ];
            if ( $ids ) {
                $ids = preg_replace( '/^,/', '', $ids );
                $ids = preg_replace( '/,$/', '', $ids );
                $where = " {$prefix}_id IN ( {$ids} ) {$include_draft}";
            } else {
                $vars = $ctx->__stash[ 'vars' ];
                $folder = '';
                if ( $vars[ 'folder_customobject_archive' ] ) {
                    if ( $category = $ctx->stash( 'category' ) ) {
                        $category_id = $category->id;
                        $folder = " AND {$prefix}_category_id=$category_id ";
                    }
                }
                $where = "{$prefix}_blog_id {$include_blogs} $folder AND {$prefix}_class = '{$class}' {$include_draft} ORDER BY {$prefix}_{$sort_by} {$sort_order}";
            }
        }
        if ( $limit ) {
            $extra[ 'limit' ] = $limit;
        }
        if ( $offset ) {
            $extra[ 'offset' ] = $offset;
        }
        $_customobject = new CustomObject;
        $customobjects = $_customobject->Find( $where, false, false, $extra );
        if ( count( $customobjects ) == 0 ) {
            $customobjects = array();
            $repeat = FALSE;
            return '';
        }
        $ctx->stash( 'customobjects', $customobjects );
    } else {
        $counter = $ctx->stash( '_customobjects_counter' );
    }
    if ( $counter < count( $customobjects ) ) {
        $customobject = $customobjects[ $counter ];
        if ( is_object( $customobject ) ) {
            $local_blog_id = $customobject->blog_id;
            $ctx->stash( 'blog', $ctx->mt->db()->fetch_blog( $local_blog_id ) );
            $ctx->stash( 'blog_id', $local_blog_id );
        }
        $ctx->stash( 'customobject', $customobject );
        $ctx->stash( '_customobjects_counter', $counter + 1 );
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $customobjects ) );
        $repeat = TRUE;
    } else {
        $ctx->restore( $localvars );
        $repeat = FALSE;
    }
    return $content;
}
function __include_exclude_blogs ( $ctx, $args ) {
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