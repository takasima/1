<?php
    global $customfield_types;
    $customfield_types[ 'entrygroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'pagegroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'entrypagegroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    // TODO::Move2Addons
    global $ctx;
    if (! isset( $ctx ) ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
    }
    require_once( 'block.mtgroupobjectsheader.php' );
    require_once( 'block.mtgroupobjectsfooter.php' );
    $ctx->add_container_tag( 'groupentriesheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'grouppagesheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupentriespagesheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupentriesfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'grouppagesfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'groupentriespagesfooter', 'smarty_block_mtgroupobjectsfooter' );

    // Backward Conpatible
    $ctx->add_container_tag( 'entrygroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'pagegroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'entrypagegroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'entrygroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'pagegroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'entrypagegroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $customfields = $ctx->stash( 'entrypagegroup_fields' );
    if (! isset( $customfields ) ) {
        require_once( 'class.mt_field.php' );
        $_field = new Field();
        $where = "field_type='entrygroup' OR field_type='pagegroup' OR field_type='entrypagegroup'";
        $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    }
    if ( is_array( $customfields ) ) {
        require_once( 'block.mtgroupentries.php' );
        require_once( 'block.mtgrouppages.php' );
        require_once( 'block.mtgroupentriespages.php' );
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsheader' );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsfooter' );
            if ( $field->field_type == 'entrygroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupentries' );
            } elseif ( $field->field_type == 'pagegroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgrouppages' );
            } elseif ( $field->field_type == 'entrypagegroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupentriespages' );
            }
        }
    }
?>