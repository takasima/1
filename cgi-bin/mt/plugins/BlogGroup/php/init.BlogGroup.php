<?php
    global $customfield_types;
    $customfield_types[ 'bloggroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'websitegroup' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'blogwebsitegroup' ] = array(
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
    $ctx->add_container_tag( 'groupblogsheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupwebsitesheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupblogswebsitesheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'groupblogsfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'groupwebsitesfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'groupblogswebsitesfooter', 'smarty_block_mtgroupobjectsfooter' );

    // Backward Conpatible
    $ctx->add_container_tag( 'bloggroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'websitegroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'blogwebsitegroupheader', 'smarty_block_mtgroupobjectsheader' );
    $ctx->add_container_tag( 'bloggroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'websitegroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    $ctx->add_container_tag( 'blogwebsitegroupfooter', 'smarty_block_mtgroupobjectsfooter' );
    require_once( 'class.mt_field.php' );
    $_field = new Field();
    $where = "field_type='bloggroup' OR field_type='websitegroup' OR field_type='blogwebsitegroup'";
    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    if ( is_array( $customfields ) ) {
        require_once( 'block.mtgroupblogs.php' );
        require_once( 'block.mtgroupwebsites.php' );
        require_once( 'block.mtgroupblogswebsites.php' );
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsheader' );
            $ctx->add_container_tag( $tag . 'header', 'smarty_block_mtgroupobjectsfooter' );
            if ( $field->field_type == 'bloggroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupblogs' );
            } elseif ( $field->field_type == 'websitegroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupwebsites' );
            } elseif ( $field->field_type == 'blogwebsitegroup' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mtgroupblogswebsites' );
            }
        }
    }
?>