<?php
    $mt = MT::get_instance();
    $ctx =& $mt->context();
    global $customfield_types;
    $customfield_types[ 'snippet' ] = array(
        'column_def' => 'vblob',
    );
    require_once( 'class.mt_field.php' );
    $_field = new Field();
    $where = "field_type='snippet'";
    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    if ( is_array( $customfields ) ) {
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->unregister_block( $tag . 'asset' );
            $ctx->add_tag( $tag, 'smarty_function_mt_snippetfield' );
            $ctx->add_container_tag( $tag . 'vars', 'smarty_block_mt_snippetfield_vars' );
            $ctx->add_container_tag( $tag . 'asset', 'smarty_block_mt_snippetfield_asset' );
        }
    }
    function smarty_block_mt_snippetfield_vars ( $args, $content, &$ctx, &$repeat ) {
        $localvars = array( 'snippet_option', '__counter__', '__snippet_option_max' );
        if (! isset( $content ) ) {
            $ctx->localize( $localvars );
            $counter = 0;
            $ctx->__stash[ 'vars' ][ '__counter__' ] = 0;
        }
        $counter = $ctx->__stash[ 'vars' ][ '__counter__' ];
        $snippet_option = $ctx->stash( 'snippet_option' );
        $max = $ctx->stash( '__snippet_option_max' );
        if (! isset( $snippet_option ) ) {
            $this_tag = $ctx->this_tag();
            if (! $this_tag ) {
                $repeat = FALSE;
                return '';
            }
            $this_tag = strtolower( $this_tag );
            $this_tag = preg_replace( '/^mt/i', '', $this_tag );
            $this_tag = preg_replace( '/vars$/i', '', $this_tag );
            $data = ___vblob_customfield_value( $args, $ctx, $this_tag );
            if (! $data ) {
                $repeat = FALSE;
                return '';
            }
            $key = $args[ 'key' ];
            if (! $key ) $key = 'snippet';
            $snippet_option = $data[ $key ];
            if (! is_array( $snippet_option ) ) {
                $snippet_option = array( $snippet_option );
            }
            $max = count( $snippet_option );
            $ctx->stash( '__snippet_option_max', $max );
            $ctx->stash( 'snippet_option', $snippet_option );
            $ctx->__stash[ 'vars' ][ '__counter__' ] = 0;
        }
        if ( $counter < $max ) {
            $count = $counter + 1;
            $value = $snippet_option[ $counter ];
            $ctx->__stash[ 'vars' ][ 'snippet_option' ] = $value;
            $ctx->__stash[ 'vars' ][ '__value__' ] = $value;
            $ctx->__stash[ 'vars' ][ '__first__' ] = ( $count == 1 );
            $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == $max );
            $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
            $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
            $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
            $repeat = TRUE;
        } else {
            $ctx->restore( $localvars );
            $repeat = FALSE;
        }
        return $content;
    }
    function smarty_block_mt_snippetfield_asset ( $args, $content, &$ctx, &$repeat ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) {
            $repeat = FALSE;
            return '';
        }
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $this_tag = preg_replace( '/asset$/i', '', $this_tag );
        $data = ___vblob_customfield_value( $args, $ctx, $this_tag );
        if (! $data ) {
            $repeat = FALSE;
            return '';
        }
        $key = $args[ 'key' ];
        if (! $key ) $key = 'snippet';
        $snippet_value = $data[ $key ];
        if ( preg_match( "/__snippet_upload_asset__([0-9]{1,})/", $snippet_value, $id ) ) {
            require_once( 'block.mtasset.php' );
            $args[ 'id' ] = $id[ 1 ];
            return smarty_block_mtasset( $args, $content, $ctx, $repeat );
        }
    }
    function smarty_function_mt_snippetfield ( $args, &$ctx ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $snippet = ___vblob_customfield_value( $args, $ctx, $this_tag );
        $key = $args[ 'key' ];
        if (! $key ) $key = 'snippet';
        $value = $snippet[ $key ];
        if ( is_array ( $value ) ) {
            $glue = $args[ 'glue' ];
            if (! $glue ) $glue = ',';
            return implode( $glue, $value );
        }
        return $snippet[ $key ];
    }
    function ___vblob_customfield_value ( $args, &$ctx, $tag = NULL ) {
        global $customfields_custom_handlers;
        $field = $ctx->stash( 'field' );
        $field or $field = $customfields_custom_handlers[ $tag ];
        if(! $field ) return '';
// for CustomObject and subclasses
//        $obj = _hdlr_customfield_obj( $ctx, $field->field_obj_type );
        $field_obj_type = $field->field_obj_type;
        $config = $ctx->mt->db()->fetch_plugin_data( 'customobjectconfig', 'configuration' );
        $custom_object = $config[ 'custom_objects' ];
        if ( $custom_object ) {
            $custom_objects = explode( ',', $custom_object );
        }
        if ( in_array( $field_obj_type, $custom_objects ) ) {
            $field_obj_type = 'customobject';
        }
        $obj = _hdlr_customfield_obj( $ctx, $field_obj_type );
// /for CustomObject and subclasses
        if (! isset( $obj ) || empty( $obj ) ) return $field->default ? $field->default : '';
        $basename = 'field.' . $field->field_basename;
        $tb_prefix = $obj->_table;
        $tb_prefix = preg_replace( "/^mt_/", '', $tb_prefix );
        $object_id = $obj->id;
// for Oracle
//        $sql  = "SELECT * FROM  `mt_{$tb_prefix}_meta` WHERE {$tb_prefix}_meta_{$tb_prefix}_id";
        $sql  = "SELECT * FROM mt_{$tb_prefix}_meta WHERE {$tb_prefix}_meta_{$tb_prefix}_id";
// /for Oracle
        $sql .= "={$object_id} AND {$tb_prefix}_meta_type = '{$basename}'";
        $meta = $ctx->mt->db()->SelectLimit( $sql, 1 );
        if ( $meta ) {
            $meta = $meta->fields[ "{$tb_prefix}_meta_vblob" ];
            $meta = preg_replace( "/^.*(SERG)/", '$1', $meta );
            $meta = $ctx->mt->db()->unserialize($meta);
        }
        return $meta;
    }
?>