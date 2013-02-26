<?php
    global $ctx;
    if (! isset( $ctx ) ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
    }
    global $customfield_types;
    $customfield_types[ 'contactform' ] = array(
        'column_def' => 'vchar',
    );
    require_once( 'class.mt_field.php' );
    $_field = new Field();
    $where = "field_type='contactform'";
    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    if ( is_array( $customfields ) ) {
        require_once( 'block.mtcontactforms.php' );
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->add_tag( $tag, 'smarty_function_mt_contactforms_function' );
            $ctx->add_container_tag( "{$tag}loop", 'smarty_block_mt_contactforms_block' );
        }
    }
    function smarty_function_mt_contactforms_function( $args, &$ctx ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
        if (! $value ) {
            return '';
        }
        if ( $args[ 'raw' ] ) {
            return $value;
        }
        $mtml = __get_contactform_tmpl( $value );
        require_once( 'modifier.mteval.php' );
        return smarty_modifier_mteval( $mtml, 1 );
    }
    function smarty_block_mt_contactforms_block( $args, $content, &$ctx, &$repeat ) {
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
        return smarty_block_mtcontactforms( $args, $content, $ctx, $repeat );
    }
    function __get_contactform_tmpl( $form_id ) {
        return <<<MTML
<mtcontactforms id="$form_id">
    <mt:If name="__first__">
    <div id="contactform">
    <form action="<mt:CGIPath><mt:ContactFormScript>" method="post"<mt:if name="config.ContactFormAllowUploadFile"> enctype="multipart/form-data"</mt:if>>
        <input type="hidden" name="__mode" value="confirm">
        <input type="hidden" name="blog_id" value="<mt:BlogID>" />
        <input type="hidden" name="id" value="<mt:ContactFormID>" />
    <MTArchiveType setvar="archive_type">
    <mt:If name="archive_type" eq="Individual">
        <input type="hidden" name="object_id" value="<mt:EntryID>" />
        <input type="hidden" name="model" value="entry" />
    <mt:ElseIf name="archive_type" eq="Page">
        <input type="hidden" name="object_id" value="<mt:PageID>" />
        <input type="hidden" name="model" value="page" />
    <mt:ElseIf name="archive_type" like="Category">
        <input type="hidden" name="object_id" value="<mt:CategoryID>" />
        <input type="hidden" name="model" value="category" />
    </mt:If>
    <div class="contact-form">
    </mt:If>
        <mt:FormElementHTML>
    <mt:If name="__last__">
        <div class="contact-form-submit">
            <input type="submit" value="<mt:Trans phrase="Confirm">" />
        </div>
    </div>
    </form>
    </div>
    </mt:If>
</mtcontactforms>
MTML;
    }
?>
