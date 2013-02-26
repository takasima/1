<?php
    global $customfield_types;
    $customfield_types[ 'objectgroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    // TODO::Move2Addons
    global $ctx;
    if (! isset( $ctx ) ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
    }
    require_once( 'class.mt_field.php' );
    $_field = new Field();
    $where = "field_type='objectgroup'";
    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    if ( is_array( $customfields ) ) {
        require_once( 'block.mtgroupobjectsheader.php' );
        require_once( 'block.mtgroupobjectsfooter.php' );
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsheader' );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsfooter' );
            $ctx->add_container_tag( $tag, 'smarty_block_mtfieldobjectgroupitems' );
        }
    }
    # FIXME: in case of '<MTIf tag="categoryclass">', error 'Tag categoryclass not found.' 
    require_once( 'function.mtcategoryclass.php' );
    $ctx->add_tag( 'categoryclass', 'smarty_function_mtcategoryclass' );
    function smarty_block_mtfieldobjectgroupitems ( $args, $content, &$ctx, &$repeat ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $value;
        if (! isset ( $content ) ) {
            $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
            if (! $value ) {
                $repeat = FALSE;
                return '';
            }
            $ctx->stash( $this_tag . '___customfield_value', $value );
        } else {
            $value = $ctx->stash( $this_tag . '___customfield_value' );
        }
        $args[ 'id' ] = $value;
        if ( $args[ 'raw' ] ) {
            return $value;
        }
        $args[ 'group_id' ] = $value;
        require_once( 'block.mtobjectgroupitems.php' );
        return smarty_block_mtobjectgroupitems( $args, $content, $ctx, $repeat );
    }
?>