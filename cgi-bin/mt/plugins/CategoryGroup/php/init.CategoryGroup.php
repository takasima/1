<?php
    global $customfield_types;
    $customfield_types[ 'categorygroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'foldergroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'categoryfoldergroup' ] = array(
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
    $ctx->add_container_tag( 'groupcategoriesheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupfoldersheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupcategoriesfoldersheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupcategoriesfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'groupfoldersfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'groupcategoriesfoldersfooter', 'smarty_block_mtgroupobjectsfooter' );

    // Backward Conpatible
    $ctx->add_container_tag( 'categorygroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'foldergroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'categoryfoldergroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'categorygroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'foldergroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'categoryfoldergroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    require_once( 'class.mt_field.php' );
    $_field = new Field();
    $where = "field_type='categorygroup' OR field_type='foldergroup' OR field_type='categoryfoldergroup'";
    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    if ( is_array( $customfields ) ) {
        require_once( 'block.mtgroupcategories.php' );
        require_once( 'block.mtgroupfolders.php' );
        require_once( 'block.mtgroupcategoriesfolders.php' );
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsheader' );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsfooter' );
            if ( $field->field_type == 'categorygroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupcategories' );
            } elseif ( $field->field_type == 'foldergroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupfolders' );
            } elseif ( $field->field_type == 'categoryfoldergroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupcategoriesfolders' );
            }
        }
    }
?>