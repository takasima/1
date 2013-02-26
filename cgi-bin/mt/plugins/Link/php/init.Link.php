<?php
    global $mt;
    $ctx = &$mt->context();
    global $customfield_types;
    $customfield_types[ 'link' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'link_multi' ] = array(
        'column_def' => 'vchar_idx',
    );
    $customfield_types[ 'link_group' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfields = $ctx->stash( 'link_fields' );
    if (! isset( $customfields ) ) {
        require_once( 'class.mt_field.php' );
        $_field = new Field();
        $where = "field_type='link' OR field_type='link_multi' OR field_type='link_group'";
        $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    }
    if ( is_array( $customfields ) ) {
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            if ( $field->field_type == 'link' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_link' );
            } elseif ( $field->field_type == 'link_multi' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_links' );
            } elseif ( $field->field_type == 'link_group' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_linkgroup' );
            }
        }
    }
    function smarty_block_mt_related_link ( $args, $content, &$ctx, &$repeat ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
        if (! $value ) {
            $repeat = FALSE;
            return '';
        }
        $args[ 'id' ] = $value;
        if ( $args[ 'raw' ] ) {
            return $value;
        }
        require_once( 'block.mtlinkblock.php' );
        return smarty_block_mtlinkblock( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_related_links ( $args, $content, &$ctx, &$repeat ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
        if (! $value ) {
            $repeat = FALSE;
            return '';
        }
        $value = preg_replace( '/^,/', '', $value );
        $value = preg_replace( '/,$/', '', $value );
        $args[ 'ids' ] = $value;
        if ( $args[ 'raw' ] ) {
            return $value;
        }
        require_once( 'block.mtlinks.php' );
        return smarty_block_mtlinks( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_related_linkgroup ( $args, $content, &$ctx, &$repeat ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
        if (! $value ) {
            $repeat = FALSE;
            return '';
        }
        if ( $args[ 'raw' ] ) {
            return $value;
        }
        $args[ 'group_id' ] = $value;
        require_once( 'block.mtlinks.php' );
        return smarty_block_mtlinks( $args, $content, $ctx, $repeat );
    }
?>