<?php
    // TODO::to Custom Callback of DynamicMTML
    global $ctx;
    if (! isset( $ctx ) ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
    }
    $customfields = $ctx->stash( 'customobject_fields' );
    if (! isset( $customfields ) ) {
        require_once( 'class.mt_field.php' );
        $_field = new Field();
        $where = "field_customobject=1";
        $custom_objects = array();
        $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    }
    if ( is_array( $customfields ) ) {
        require_once( 'block.mtcustomobject.php' );
        require_once( 'block.mtcustomobjects.php' );
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $field_type = $field->field_type;
            if ( preg_match( "/_multi$/", $field_type ) ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_customobject_multi' );
            } elseif ( preg_match( "/_group$/", $field_type ) ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_customobject_group' );
            } else {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_customobject_block' );
            }
        }
    }
    global $custom_objects;
    global $custom_object_class_names;
    global $custom_object_class_plurals;
    global $custom_object_archive_types;
    if ( is_array( $custom_objects ) ) {
        // TODO::Load Order
        $counter = 0;
        require_once( 'block.mtcustomobjectauthor.php' );
        require_once( 'block.mtcustomobjectiftagged.php' );
        require_once( 'block.mtcustomobjects.php' );
        require_once( 'block.mtcustomobject.php' );
        require_once( 'block.mtcustomobjectsfooter.php' );
        require_once( 'block.mtcustomobjectsheader.php' );
        require_once( 'block.mtcustomobjecttags.php' );
        // require_once( 'function.mtcustomobjectlabel.php' );
        require_once( 'function.mtcustomobjectauthordisplayname.php' );
        require_once( 'function.mtcustomobjectauthoredon.php' );
        require_once( 'function.mtcustomobjectblogid.php' );
        require_once( 'function.mtcustomobjectcreatedon.php' );
        require_once( 'function.mtcustomobjectperiodon.php' );
        require_once( 'function.mtcustomobjectid.php' );
        require_once( 'function.mtcustomobjectbasename.php' );
        require_once( 'function.mtcustomobjectpermalink.php' );
        require_once( 'function.mtcustomobjectfolderlink.php' );
        require_once( 'function.mtcustomobjectmodifiedon.php' );
        require_once( 'function.mtcustomobjectname.php' );
        require_once( 'function.mtcustomobjectbody.php' );
        require_once( 'function.mtcustomobjectkeywords.php' );
        require_once( 'block.mtcustomobjectfolder.php' );
        foreach ( $custom_objects as $object ) {
            if ( $object != 'customobject' ) {
                $prefix = $custom_object_class_names[ $counter ];
                $plural = $custom_object_class_plurals[ $counter ];
                $ctx->add_container_tag( $plural, 'smarty_block_mt_customobjects_alt' );
                $ctx->add_container_tag( $object, 'smarty_block_mtcustomobject' );
                $ctx->add_container_tag( $plural . 'header', 'smarty_block_mtcustomobjectsheader' );
                $ctx->add_container_tag( $plural . 'footer', 'smarty_block_mtcustomobjectsfooter' );
                $ctx->add_container_tag( $object . 'author', 'smarty_block_mtcustomobjectauthor' );
                $ctx->add_conditional_tag( $object . 'iftagged', 'smarty_block_mtcustomobjectiftagged' );
                $ctx->add_container_tag( $object . 'folder', 'smarty_block_mtcustomobjectfolder' );
                $ctx->add_container_tag( $object . 'tags', 'smarty_block_mtcustomobjecttags' );
                $ctx->add_tag( $object . 'authordisplayname', 'smarty_function_mtcustomobjectauthordisplayname' );
                $ctx->add_tag( $object . 'name', 'smarty_function_mtcustomobjectname' );
                $ctx->add_tag( $object . 'body', 'smarty_function_mtcustomobjectbody' );
                $ctx->add_tag( $object . 'keywords', 'smarty_function_mtcustomobjectkeywords' );
                $ctx->add_tag( $object . 'authoredon', 'smarty_function_mtcustomobjectauthoredon' );
                $ctx->add_tag( $object . 'periodon', 'smarty_function_mtcustomobjectperiodon' );
                $ctx->add_tag( $object . 'blogid', 'smarty_function_mtcustomobjectblogid' );
                $ctx->add_tag( $object . 'createdon', 'smarty_function_mtcustomobjectcreatedon' );
                $ctx->add_tag( $object . 'modifiedon', 'smarty_function_mtcustomobjectmodifiedon' );
                $ctx->add_tag( $object . 'id', 'smarty_function_mtcustomobjectid' );
                $ctx->add_tag( $object . 'basename', 'smarty_function_mtcustomobjectbasename' );
                $ctx->add_tag( $object . 'permalink', 'smarty_function_mtcustomobjectpermalink' );
                $ctx->add_tag( $object . 'folderlink', 'smarty_function_mtcustomobjectfolderlink' );
                $ctx->add_tag( $object . 'label', 'smarty_function_mtcustomobjectlabel_alt' );
                $ctx->add_tag( $plural . 'count', 'smarty_function_mtcustomobjectscount_alt' );
            }
            $counter++;
        }
    }
    function smarty_block_mt_customobjects_alt ( $args, $content, &$ctx, &$repeat ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        global $custom_object_class_plurals;
        global $custom_object_class_names;
        $counter = 0;
        $class;
        foreach ( $custom_object_class_plurals as $plural ) {
            if ( $plural == $this_tag ) {
                $class = $custom_object_class_names[ $counter ];
                break;
            }
            $counter++;
        }
        $args[ 'class' ] = $class;
        return smarty_block_mtcustomobjects( $args, $content, $ctx, $repeat );
    }
    function smarty_function_mtcustomobjectlabel_alt ( $args, &$ctx ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt(.*?)label$/i', '$1', $this_tag );
        $args[ 'component' ] = $this_tag;
        require_once( 'function.mtcustomobjectlabel.php' );
        return smarty_function_mtcustomobjectlabel( $args, $ctx );
    }
    function smarty_function_mtcustomobjectscount_alt ( $args, &$ctx ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt(.*?)scount$/i', '$1', $this_tag );
        $args[ 'class' ] = $this_tag;
        require_once( 'function.mtcustomobjectscount.php' );
        return smarty_function_mtcustomobjectscount( $args, $ctx );
    }
    function smarty_block_mt_customobject_block ( $args, $content, &$ctx, &$repeat ) {
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
        return smarty_block_mtcustomobject( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_customobject_multi ( $args, $content, &$ctx, &$repeat ) {
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
        return smarty_block_mtcustomobjects( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_customobject_group ( $args, $content, &$ctx, &$repeat ) {
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
        return smarty_block_mtcustomobjects( $args, $content, $ctx, $repeat );
    }
    global $customfield_types;
    $customfield_types[ 'customobject' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_customobject',
            'author' =>  'customfield_html_customobject_author',
        ),
        'column_def' => 'vchar',
    );
    $customfield_types[ 'customobject_multi' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_customobject_multi',
            'author' =>  'customfield_html_customobject_multi_author',
        ),
        'column_def' => 'vchar',
    );
    $customfield_types[ 'customobject_group' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_customobject',
            'author' =>  'customfield_html_customobject_author',
        ),
        'column_def' => 'vinteger_idx',
    );
    function customfield_html_customobject ( &$ctx, $param ) {
        extract( $param );
        require_once( "MTUtil.php" );
        $field_name = encode_html( $field_name );
        $field_value = encode_html( $field_value );
        // TODO:: Set $field_value to $object->name.
        return <<<EOT
    <div class="textarea-wrapper">
    <input type="text" name="$field_name" id="$field_id" value="$field_value" class="full-width ti" />
    </div>
EOT;
    }
    function customfield_html_customobject_author ( &$ctx, $param ) {
        extract( $param );
        require_once( "MTUtil.php" );
        $field_name = encode_html( $field_name );
        $field_value = encode_html( $field_value );
        // TODO:: Set $field_value to $object->name.
        return <<<EOT
    <div class="textarea-wrapper">
    <input type="text" name="$field_name" id="$field_id" value="$field_value" class="half-width" />
    </div>
EOT;
    }
    function customfield_html_customobject_multi ( &$ctx, $param ) {
        extract( $param );
        require_once( "MTUtil.php" );
        $field_name = encode_html( $field_name );
        $field_value = encode_html( $field_value );
        // TODO:: Set $field_value to $object->name.
        return <<<EOT
    <div class="textarea-wrapper">
    <input type="text" name="$field_name" id="$field_id" value="$field_value" class="full-width ti" />
    </div>
EOT;
    }
    function customfield_html_customobject_multi_author ( &$ctx, $param ) {
        extract( $param );
        require_once( "MTUtil.php" );
        $field_name = encode_html( $field_name );
        $field_value = encode_html( $field_value );
        // TODO:: Set $field_value to $object->name.
        return <<<EOT
    <div class="textarea-wrapper">
    <input type="text" name="$field_name" id="$field_id" value="$field_value" class="half-width" />
    </div>
EOT;
    }
    
    // init customfields for subclass(include customobject).
    $_field = new Field();
    $where_field_obj_type = array();
    foreach ( $custom_objects as $object ) {
        if ( $object != 'customobject' ) {
            $where_field_obj_type[] = "field_obj_type='$object'";
        }
    }
    $where = implode( ' OR ', $where_field_obj_type );
//    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
// for Oracle
    if ( $where ) {
        $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    }
// /for Oracle
    if ( is_array( $customfields ) ) {
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            $ctx->add_tag( $tag, 'smarty_block_mt_customobject' );
            if ( preg_match( '/^video|image|file|audio/', $field->field_type ) ) {
                $fn_name = $field->field_id . '_customobejct';
                $asset_fn = <<<CODE
function customfield_asset_$fn_name(\$args, \$content, &\$ctx, &\$repeat) {
    return __hdlr_customfield_asset(\$args, \$content, \$ctx, \$repeat, '$tag');
}
CODE;
                eval( $asset_fn );
                $ctx->add_container_tag( $tag . $field->type, 'customfield_asset_' . $fn_name );
                $ctx->add_container_tag( $tag . 'asset', 'customfield_asset_' . $fn_name );
            }
        }
    }
    function smarty_block_mt_customobject ( $args, &$ctx ) {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = strtolower( $this_tag );
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $value = __hdlr_customfield_value( $args, $ctx, $this_tag );
        return $value;
    }

    // following is from function '_hdlr_customfield_value' in 'init.CustomFields.php', and 'ADD' is added.
    function __hdlr_customfield_value($args, &$ctx, $tag = null) {
        global $customfields_custom_handlers;
        $field = $ctx->stash('field');
        $field or $field = $customfields_custom_handlers[$tag];
        if(!$field) return '';
    
        // ADD
        $field->field_obj_type = 'customobject';
        // /ADD
        $obj = _hdlr_customfield_obj($ctx, $field->field_obj_type);
        if(!isset($obj) || empty($obj)) return $field->default ? $field->default : '';
    
        $real_type = $field->field_obj_type;
        if ($real_type == 'folder')
            $real_type = 'category';
        elseif ($real_type == 'page')
            $real_type = 'entry';
    
        $text = $obj->{$obj->_prefix . 'field.' . $field->field_basename};
        if (preg_match('/\smt:asset-id="\d+"/', $text) && !$args['no_asset_cleanup']) {
            require_once("MTUtil.php");
            $text = asset_cleanup($text);
        }
    
        if($field->field_type == 'textarea') {
            $cb = $obj->entry_convert_breaks;
            if (isset($args->convert_breaks)) {
                $cb = $args->convert_breaks;
            } elseif (!isset($cb)) {
                $blog = $ctx->stash('blog');
                $cb = $blog->blog_convert_paras;
            }
            if ($cb) {
                if (($cb == '1') || ($cb == '__default__')) {
                    # alter EntryBody, EntryMore in the event that
                    # we're doing convert breaks
                    $cb = 'convert_breaks';
                }
                require_once 'MTUtil.php';
                $text = apply_text_filter($ctx, $text, $cb);
            }
        }
    
        if (array_key_exists('label', $args) && $args['label']) {
            $value_label = '';
            $type_obj = $customfield_types[$field->field_type];
            if (array_key_exists('options_delimiter', $type_obj)) {
                $option_loop = array();
                $expr = '\s*' . preg_quote($type_obj->options_delimiter) . '\s*';
                $options = preg_split('/' . $expr . '/', $field->field_options);
                foreach ($options as $option) {
                    $label = $option;
                    if (preg_match('/=/', $option))
                        list($option, $label) = preg_split('/\s*=\s*/', $option, 2);
                    if ($text == $option) {
                        $value_label = $label;
                        break;
                    }
                }
            }
            $text = $value_label;
        }
    
        if($field->field_type == 'datetime') {
            $text = preg_replace('/\D/', '', $text);
            if (($text == '') or ($text == '00000000'))
                return '';
            if (strlen($text) == 8) {
                $text .= '000000';
            }
            $args['ts'] = $text;
            if ($field->field_options == 'date') {
                if ( !isset( $args['format'] ) )
                    $args['format'] = '%x';
            } elseif ($field->field_options == 'time') {
                if ( !isset( $args['format'] ) )
                    $args['format'] = '%X';
            }
            return $ctx->_hdlr_date($args, $ctx);
        }
    
        return $text;
    }

    // following is from function '__hdlr_customfield_asset' in 'init.CustomFields.php', and 'PATCH' is patched.
    function __hdlr_customfield_asset($args, $content, &$ctx, &$repeat, $tag = null) {
        $localvars = array('assets', 'asset', '_assets_counter', 'blog', 'blog_id');
        if (!isset($content)) {
            $ctx->localize($localvars);
            $blog_id = $ctx->stash('blog_id');
    
            $args['no_asset_cleanup'] = 1;
            // PATCH
//            $value = _hdlr_customfield_value($args, $ctx, $tag);
            $value = __hdlr_customfield_value($args, $ctx, $tag);
            // /PATCH

            $args['blog_id'] = $blog_id;
            if(preg_match('!<form[^>]*?\smt:asset-id=["\'](\d+)["\'][^>]*?>(.+?)</form>!is', $value, $matches)) {
                $args['id'] = $matches[1];
            } else {
                $ctx->restore($localvars);
                $repeat = false;
                return '';
            }
    
            $assets = $ctx->mt->db()->fetch_assets($args);
            $ctx->stash('assets', $assets);
            $counter = 0;
        } else {
            $assets = $ctx->stash('assets');
            $counter = $ctx->stash('_assets_counter');
        }
        if ($counter < count($assets)) {
            $asset = $assets[$counter];
            $ctx->stash('asset', $asset);
            $ctx->stash('_assets_counter', $counter + 1);
            $repeat = true;
        } else {
            $ctx->restore($localvars);
            $repeat = false;
        }
        return $content;
    }
?>