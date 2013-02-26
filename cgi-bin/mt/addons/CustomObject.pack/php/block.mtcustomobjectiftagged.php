<?php
function smarty_block_mtcustomobjectiftagged( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $customobject = $ctx->stash( 'customobject' );
        if ( $customobject ) {
            $customobject_id = $customobject->id;
            $tag = $args[ 'name' ];
            $tag or $tag = $args[ 'tag' ];
            $targs = array( 'customobject_id' => $customobject_id );
            if ( $tag && ( substr( $tag, 0, 1 ) == '@' ) ) {
                $targs[ 'include_private' ] = 1;
            }
            require_once( 'block.mtcustomobjecttags.php' );
            $tags = fetch_customobject_tags( $ctx, $targs );
            if ( $tag && $tags ) {
                $has_tag = 0;
                foreach ( $tags as $row ) {
                    $row_tag = $row->tag_name;
                    if ( $row_tag == $tag ) {
                        $has_tag = 1;
                        break;
                    }
                }
            } else {
//                $has_tag = count( $tags ) > 0;
                include_once( 'customobject.util.php' );
                $prefix = __init_customobject_class ( $ctx );
                $where = "{$prefix}_id = $customobject_id"
                       . " AND objecttag_object_datasource = '{$prefix}'"
                       ;
                $extra[ 'join' ] = array(
                    'mt_objecttag' => array(
                        'condition' => "{$prefix}_id=objecttag_object_id",
                    ),
                );
                $_customobject = new CustomObject;
                $customobject = $_customobject->Find( $where, false, false, $extra );
                $has_tag = $customobject ? TRUE : FALSE;
            }
        }
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $has_tag );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>