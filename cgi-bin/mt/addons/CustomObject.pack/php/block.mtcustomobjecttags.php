<?php
function smarty_block_mtcustomobjecttags( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( '_tags', 'Tag', '_tags_counter', 'tag_min_count', 'tag_max_count', 'all_tag_count', '__out', 'class_type' );
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        require_once( 'MTUtil.php' );
        $customobject = $ctx->stash( 'customobject' );
        if (! isset( $customobject ) ) {
            return;
        }
        $blog_id = $customobject->blog_id;
        $tags = fetch_customobject_tags( $ctx, array( 'customobject_id' => $customobject->id, 'blog_id' => $blog_id ) );
        if (! is_array( $tags ) ) $tags = array();
        $ctx->stash( '_tags', $tags );
        $ctx->stash( '__out', false );
        $ctx->stash( 'class_type', 'customobject' );
        $counter = 0;
    } else {
        $tags = $ctx->stash( '_tags' );
        $counter = $ctx->stash( '_tags_counter' );
        $out = $ctx->stash( '__out' );
    }
    if ( $counter < count( $tags ) ) {
        $tag = $tags[ $counter ];
        $ctx->stash( 'Tag', $tag );
        $ctx->stash( '_tags_counter', $counter + 1 );
        $repeat = true;
        if ( isset( $args[ 'glue' ] ) && !empty( $content ) ) {
            if ( $out )
                $content = $args[ 'glue' ] . $content;
            else
                $ctx->stash( '__out', true );
        }
    } else {
        if ( isset( $args[ 'glue' ] ) && $out && !empty( $content ) )
            $content = $args[ 'glue' ] . $content;
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
function fetch_customobject_tags( $ctx, $args ) {
    if (! isset( $args[ 'include_private' ] ) ) {
        $private_filter = 'and (tag_is_private = 0 or tag_is_private is null)';
    }
    if ( isset( $args[ 'customobject_id' ] ) ) {
        if ( isset( $args[ 'tags' ] ) ) {
            if ( isset( $ctx->mt->db()->_customobject_tag_cache[ $args[ 'customobject_id' ] ] ) )
                return $ctx->mt->db()->_customobject_tag_cache[ $args[ 'customobject_id' ] ];
        }
        $customobject_filter = 'and objecttag_object_id = '.intval( $args[ 'customobject_id' ] );
    }
    if ( isset( $args[ 'blog_id' ] ) ) {
        if (! isset( $args[ 'tags' ] ) ) {
            if ( isset( $ctx->mt->db()->_blog_customobject_tag_cache[ $args[ 'blog_id' ] ] ) )
                return $ctx->mt->db()->_blog_customobject_tag_cache[ $args[ 'blog_id' ] ];
        }
        $blog_filter = 'and objecttag_blog_id = '.intval( $args[ 'blog_id' ] );
    }
    if ( isset( $args[ 'tags' ] ) && ( $args[ 'tags' ] != '' ) ) {
        $tag_list = '';
        require_once( 'MTUtil.php' );
        $tag_array = tag_split( $args[ 'tags' ] );
        foreach ( $tag_array as $tag ) {
            if ( $tag_list != '' ) $tag_list .= ',';
            $tag_list .= "'" . $ctx->mt->db()->escape( $tag ) . "'";
        }
        if ( $tag_list != '' ) {
            $tag_filter = 'and (tag_name in (' . $tag_list . '))';
            $private_filter = '';
        }
    }
    $sort_col = isset( $args[ 'sort_by' ] ) ? $args[ 'sort_by' ] : 'name';
    $sort_col = "tag_$sort_col";
    if ( isset( $args[ 'sort_order' ] ) and $args[ 'sort_order' ] == 'descend' ) {
        $order = 'desc';
    } else {
        $order = 'asc';
    }
    $id_order = '';
    if ( $sort_col == 'tag_name' ) {
        $sort_col = 'lower(tag_name)';
    } else {
        $id_order = ', lower(tag_name)';
    }
    include_once( 'customobject.util.php' );
    $prefix = __init_customobject_class ( $ctx );
    $sql = "
        select tag_id, tag_name, count(*) as tag_count
        from mt_tag, mt_objecttag, mt_{$prefix}
        where objecttag_tag_id = tag_id
            and {$prefix}_id = objecttag_object_id and objecttag_object_datasource='{$prefix}'
            $blog_filter
            $private_filter
            $tag_filter
            $customobject_filter
        group by tag_id, tag_name
        order by $sort_col $order $id_order
    ";
    $rs = $ctx->mt->db()->SelectLimit( $sql );
    require_once( 'class.mt_tag.php' );
    $tags = array();
    while(! $rs->EOF ) {
        $tag = new Tag;
        $tag->tag_id = $rs->Fields( 'tag_id' );
        $tag->tag_name = $rs->Fields( 'tag_name' );
        $tag->tag_count = $rs->Fields( 'tag_count' );
        $tags[] = $tag;
        $rs->MoveNext();
    }
    if ( isset( $args[ 'tags' ] ) ) {
        if ( $args[ 'customobject_id' ] )
            $ctx->mt->db()->_customobject_tag_cache[ $args[ 'customobject_id' ] ] = $tags;
        elseif ( $args[ 'blog_id' ] )
            $ctx->mt->db()->_blog_customobject_tag_cache[ $args[ 'blog_id' ] ] = $tags;
    }
    return $tags;
}
?>