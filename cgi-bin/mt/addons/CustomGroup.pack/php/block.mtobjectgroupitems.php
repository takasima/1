<?php
function smarty_block_mtobjectgroupitems( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'blog', 'blog_id', 'category', 'entry', 'object_ds', 'class', '_objects_counter', 'objects', 'inside_mt_categories' );
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $id = $args[ 'id' ];
        $name = $args[ 'name' ];
        if (! isset( $name ) ) {
            $name = $args[ 'group' ];
        }
        $blog_id = $args[ 'blog_id' ];
        if ( $ctx->__stash[ 'objects' ] ) {
            $ctx->__stash[ 'objects' ] = NULL;
        }
        if ( !$id ) {
            $terms = array();
            if ( $name ) {
                $terms[] = " objectgroup_name = '$name' ";
            }
            if ( $blog_id ) {
                $terms[] = " objectgroup_blog_id = '$blog_id' ";
            }
            if (! $terms ) {
                $ctx->restore( $localvars );
                $repeat = false;
                return '';
            }
            require_once 'class.mt_objectgroup.php';
            $_group = new ObjectGroup;
            $where = implode(' AND ', $terms);
            $extra = array(
                'limit'  => 1,
                'offset' => 0,
            );
            $results = $_group->Find( $where, false, false, $extra );
            $group = $results[0];
            if ( $group ) {
                $id      = $group->objectgroup_id;
                $blog_id = $group->objectgroup_blog_id;
            }
        }
        if (! $id ) {
            $ctx->restore( $localvars );
            $repeat = false;
            return '';
        }
        $sort_order = $args[ 'sort_order' ];
        if ( $sort_order == 'descend' ) {
            $sort_order = 'DESC';
        } else {
            $sort_order = 'ASC';
        }
        if ( $args[ 'lastn' ] ) {
            $lastn = $args[ 'lastn' ];
        } else {
            $lastn = 9999;
        }
        require_once 'class.mt_objectorder.php';
        $_order = new ObjectOrder;
        $where = "objectorder_objectgroup_id = {$id} "
               . " ORDER BY objectorder_number {$sort_order} "
               ;
        $extra = array();
        if ( $lastn ) {
            $extra[ 'limit' ] = $lastn;
        }
        $results = $_order->Find( $where, false, false, $extra );
        if ( ! isset( $results ) ) {
            $ctx->restore( $localvars );
            $repeat = false;
            return '';
        }
        $objects = array();
        $blogs   = array();
        foreach ($results as $order) {
            $object_ds = $order->objectorder_object_ds;
            $class     = $order->objectorder_class;
            $id        = $order->objectorder_object_id;
            $blog      = NULL;
            $category  = NULL;
            $entry     = NULL;
            $db =& $ctx->mt->db();
            
            if ( $class == 'blog' ) {
                $blog = $ctx->mt->db()->fetch_blog( $id );
                $ctx->stash( 'blog', $blog );
            } elseif ( $class == 'website' ) {
                $blog = $ctx->mt->db()->fetch_website( $id );
                $ctx->stash( 'blog', $blog );
            } elseif ( $class == 'category' ) {
                $ctx->stash( 'category', $category );
                $category = $ctx->mt->db()->fetch_category( $id );
                $blog_id  = $category->category_blog_id;
            } elseif ( $class == 'folder' ) {
                $ctx->stash( 'category', $category );
                $category = $ctx->mt->db()->fetch_folder( $id );
                $blog_id  = $category->category_blog_id;
            } elseif ( $class == 'entry' ) {
                $entry   = $ctx->mt->db()->fetch_entry( $id );
                $blog_id = $entry->entry_blog_id;
            } elseif ( $class == 'page' ) {
                $entry   = $ctx->mt->db()->fetch_page( $id );
                $blog_id = $entry->entry_blog_id;
            }
            if (!isset ( $blog ) ) {
                if ( $blogs[ 'blog_' . $blog_id ] ) {
                    $blog = $blogs[ 'blog_' . $blog_id ];
                }
            }
            if ( $blog ) {
                $blogs[ 'blog_' . $blog->blog_id ] = $blog;
            }
            $object         = array();
            $object['blog'] = $blog;
            if ( $blog ) {
                $object['blog_id'] = $blog->blog_id;
            }
            $object['category']  = $category;
            $object['entry']     = $entry;
            $object['object_ds'] = $object_ds;
            $object['class']     = $class;
            $objects[]           = $object;
        }
        $ctx->stash( 'objects', $objects );
        $counter = 0;
    } else {
        $objects = $ctx->stash( 'objects' );
        $counter = $ctx->stash( '_objects_counter' );
    }
    if ( $counter < count( $objects ) ) {
        $object = $objects[ $counter ];
        $ctx->stash( 'blog', $object['blog'] );
        $ctx->stash( 'blog_id', $object['blog_id'] );
        $ctx->stash( 'category', $object['category'] );
        $ctx->stash( 'entry', $object['entry'] );
        $ctx->stash( 'object_ds', $object['object_ds'] );
        $ctx->stash( 'class', $object['class'] );
        $ctx->stash( '_objects_counter', $counter + 1 );
        $ctx->__stash['vars']['__counter__'] = $count;
        $ctx->__stash['vars']['__odd__'] = ( $count % 2 ) == 1;
        $ctx->__stash['vars']['__even__'] = ( $count % 2 ) == 0;
        $ctx->__stash['vars']['__first__'] = $count == 1;
        $ctx->__stash['vars']['__last__'] = ( $count == count( $objects ) );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>
