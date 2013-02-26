<?php
    global $ctx;
    if (! isset( $ctx ) ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
    }
    require_once( 'class.baseobject.php' );
    require_once( 'class.mt_field.php' );
    $fld = new Field();
    $fields = $fld->Find( '1 = 1' );
    $blogwebsitegroup_fields = array();
    $categoryfoldergroup_fields = array();
    $entrypagegroup_fields = array();
    $snippet_fields = array();
    $campaign_fields = array();
    $link_fields = array();
    $contactform_fields = array();
    $customobject_fields = array();
    $additional_fields = array();
    if ( !empty( $fields ) ) {
        foreach ( $fields as $field ) {
            $type = $field->type;
            if ( ( $type == 'bloggroup' ) ||
                ( $type == 'websitegroup' ) || ( $type == 'blogwebsitegroup' ) ) {
                array_push( $blogwebsitegroup_fields, $field );
            } elseif ( ( $type == 'entrygroup' ) ||
                ( $type == 'pagegroup' ) || ( $type == 'entrypagegroup' ) ) {
                array_push( $entrypagegroup_fields, $field );
            } elseif ( $type == 'snippet' ) {
                array_push( $snippet_fields, $field );
            } elseif ( ( $type == 'campaign' ) ||
                ( $type == 'campaign_multi' ) || ( $type == 'campaign_group' ) ) {
                array_push( $campaign_fields, $field );
            } elseif ( ( $type == 'link' ) ||
                ( $type == 'link_multi' ) || ( $type == 'link_group' ) ) {
                array_push( $link_fields, $field );
            } elseif ( $type == 'contactform' ) {
                array_push( $contactform_fields, $field );
            } elseif ( ( $type == 'entry' ) ||
                ( $type == 'entry_multi' ) || ( $type == 'page' ) ||
                ( $type == 'page_multi' ) || ( $type == 'checkbox_multi' ) ||
                ( $type == 'dropdown_multi' ) ) {
                array_push( $additional_fields, $field );
            } else {
                if ( $field->customobject ) {
                    array_push( $customobject_fields, $field );
                }
            }
        }
    }
    $ctx->stash( 'blogwebsitegroup_fields', $blogwebsitegroup_fields );
    $ctx->stash( 'categoryfoldergroup_fields', $categoryfoldergroup_fields );
    $ctx->stash( 'entrypagegroup_fields', $entrypagegroup_fields );
    $ctx->stash( 'snippet_fields', $snippet_fields );
    $ctx->stash( 'campaign_fields', $campaign_fields );
    $ctx->stash( 'link_fields', $link_fields );
    $ctx->stash( 'contactform_fields', $contactform_fields );
    $ctx->stash( 'additional_fields', $additional_fields );
    $ctx->stash( 'customobject_fields', $customobject_fields );
?>