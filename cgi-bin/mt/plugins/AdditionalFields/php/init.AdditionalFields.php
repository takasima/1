<?php
    global $mt;
    $ctx = &$mt->context();
    global $customfield_types;
    $customfield_types[ 'checkbox_multi' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_checkbox_multi',
            'author'  => 'customfield_html_checkbox_multi',
        ),
        'column_def' => 'vchar',
    );
    $customfield_types[ 'dropdown_multi' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_dropdown_multi',
            'author'  => 'customfield_html_dropdown_multi',
        ),
        'column_def' => 'vchar',
    );
    $customfield_types[ 'entry' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'page' ] = array(
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'entry_multi' ] = array(
        'column_def' => 'vchar_idx',
    );
    $customfield_types[ 'page_multi' ] = array(
        'column_def' => 'vchar_idx',
    );
    $customfield_types[ 'ninteger' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_text',
            'author'  => 'customfield_html_text',
        ),
        'column_def' => 'vinteger_idx',
    );
    $customfield_types[ 'nfloat' ] = array(
        'field_html' => array (
            'default' => 'customfield_html_text',
            'author'  => 'customfield_html_text',
        ),
        'column_def' => 'vfloat_idx',
    );
    require_once( 'class.mt_field.php' );
    $_field = new Field();
    $where = "field_type='entry' OR field_type='entry_multi' OR field_type='page' OR field_type='page_multi'";
    $where .=" OR field_type='checkbox_multi' OR field_type='dropdown_multi'";
    $customfields = $_field->Find( $where, FALSE, FALSE, array() );
    if ( is_array( $customfields ) ) {
        foreach ( $customfields as $field ) {
            $tag = $field->tag;
            $tag = strtolower( $tag );
            $ctx->unregister_function( $tag );
            if ( $field->field_type == 'entry' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_entry' );
            } elseif ( $field->field_type == 'entry_multi' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_entries' );
            } elseif ( $field->field_type == 'page' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_page' );
            } elseif ( $field->field_type == 'page_multi' ) {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_related_pages' );
            } else {
                $ctx->add_container_tag( $tag, 'smarty_block_mt_multiplefield' );
            }
        }
    }
    function smarty_block_mt_related_entry ( $args, $content, &$ctx, &$repeat ) {
        $args[ 'class' ] = 'entry';
        return smarty_block_mt_related_entry_block( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_related_page ( $args, $content, &$ctx, &$repeat ) {
        $args[ 'class' ] = 'page';
        return smarty_block_mt_related_entry_block( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_related_entries ( $args, $content, &$ctx, &$repeat ) {
        $args[ 'class' ] = 'entry';
        return smarty_block_mt_related_entries_block( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_related_pages ( $args, $content, &$ctx, &$repeat ) {
        $args[ 'class' ] = 'page';
        return smarty_block_mt_related_entries_block( $args, $content, $ctx, $repeat );
    }
    function smarty_block_mt_related_entry_block ( $args, $content, &$ctx, &$repeat ) {
        $localvars = array( 'entry', 'field_value' );
        if (! isset( $content ) ) {
            $ctx->localize( $localvars );
            $this_tag = $ctx->this_tag();
            if (! $this_tag ) return;
            $this_tag = strtolower( $this_tag );
            $this_tag = preg_replace( '/^mt/i', '', $this_tag );
            $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
            if (! $value ) {
                $repeat = FALSE;
                return;
            }
            $ctx->stash( 'field_value', $value );
            $entry;
            if (! $args[ 'raw' ] ) {
                if ( $args[ 'class' ] == 'entry' ) {
                    $entry = $ctx->mt->db()->fetch_entry( $value );
                } else {
                    $entry = $ctx->mt->db()->fetch_page( $value );
                }
            }
            $ctx->stash( 'entry', $entry );
            $repeat = TRUE;
        } else {
            $field_value = $ctx->stash( 'field_value' );
            if ( $args[ 'raw' ] ) {
                $ctx->restore( $localvars );
                $repeat = FALSE;
                return $field_value;
            }
            $entry = $ctx->stash( 'entry' );
            $ctx->stash( 'entry', $entry );
            $ctx->stash( 'blog', $entry->blog() );
            $ctx->stash( 'blog_id', $entry->blog_id );
            $ctx->restore( $localvars );
            $repeat = FALSE;
        }
        return $content;
    }
    function smarty_block_mt_related_entries_block ( $args, $content, &$ctx, &$repeat ) {
        $localvars = array( 'entry', 'entries', 'field_value', '__ctx_inside_mt_entry',
                            '__related_entries_count', '__related_entries_counter' );
        if (! isset( $content ) ) {
            $ctx->localize( $localvars );
            $this_tag = $ctx->this_tag();
            if (! $this_tag ) return;
            $this_tag = strtolower( $this_tag );
            $this_tag = preg_replace( '/^mt/i', '', $this_tag );
            $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
            $value = preg_replace( '/^,/', '', $value );
            $value = preg_replace( '/,$/', '', $value );
            if (! $value ) {
                $repeat = FALSE;
                return;
            }
            if ( $args[ 'raw' ] ) {
                return $value;
            }
            $ctx->stash( 'field_value', $value );
            $entries;
            $extra;
            $lastn = $args[ 'lastn' ];
            $offset = $args[ 'offset' ];
            if (! isset( $offset ) ) {
                $offset = 0;
            }
            $sort_by = $args[ 'sort_by' ];
            if ( $sort_by ) $sort_by = 'entry_' . $sort_by;
            $sort_order = $args[ 'sort_order' ];
            if ( (! isset( $sort_order ) ) || ( $sort_order == 'ascend' ) ) {
                $sort_order = 'ASC';
            } else {
                $sort_order = 'DESC';
            }
            if (! $args[ 'raw' ] ) {
                if ( $args[ 'class' ] == 'entry' ) {
                    require_once( 'class.mt_entry.php' );
                    $entries = new Entry;
                } else {
                    require_once( 'class.mt_page.php' );
                    $entries = new Page;
                }
            }
            $where = "entry_id in ({$value}) AND entry_status=2";
            if ( $sort_by ) {
                $where .= " order by $sort_by $sort_order ";
            }
            if ( $lastn ) {
                $extra = array( 'limit' => $lastn, 'offset' => $offset, 'distinct' => 1, );
            }
            $entries = $entries->Find( $where, FALSE, FALSE, $extra );
            if (! is_array( $entries ) ) {
                $ctx->restore( $localvars );
                $repeat = FALSE;
                return;
            }
            if (! $sort_by ) {
                $loaded_entries = array();
                foreach( $entries as $entry ) {
                    $loaded_entries[ $entry->id ] = $entry;
                }
                $ids = preg_split( '/,/', $value );
                if ( $sort_order == 'DESC' ) {
                    $ids = array_reverse( $ids );
                }
                $entries = array();
                foreach ( $ids as $entry_id ) {
                    if ( $entry = $loaded_entries[ $entry_id ] ) {
                        array_push( $entries, $entry );
                    }
                }
            }
            $ctx->stash( 'entries', $entries );
            $ctx->stash( '__related_entries_count', count( $entries ) );
            $ctx->stash( '__related_entries_counter', 0 );
            if ( $entry = $ctx->stash( 'entry' ) ) {
                $ctx->stash( 'entry', NULL );
                $ctx->stash( '__ctx_inside_mt_entry', $entry );
            }
        } else {
            $entries = $ctx->stash( 'entries' );
            $entries_count = $ctx->stash( '__related_entries_count' );
            $counter = $ctx->stash( '__related_entries_counter' );
            $inside_mt_entry = $ctx->stash( '__ctx_inside_mt_entry' );
            $entry = $entries[ $counter ];
            if ( $counter < $entries_count ) {
                $counter++;
                $ctx->__stash[ 'vars' ][ '__counter__' ] = $counter;
                $ctx->__stash[ 'vars' ][ '__odd__' ]     = ( $counter % 2 ) == 1;
                $ctx->__stash[ 'vars' ][ '__even__' ]    = ( $counter % 2 ) == 0;
                $ctx->__stash[ 'vars' ][ '__first__' ]   = $counter == 1;
                $ctx->__stash[ 'vars' ][ '__last__' ]    = ( $counter == $entries_count );
                $ctx->stash( 'entry', $entry );
                $ctx->stash( 'blog', $entry->blog() );
                $ctx->stash( 'blog_id', $entry->blog_id );
                $repeat = TRUE;
            } else {
                $counter++;
                $repeat = FALSE;
                $ctx->restore( $localvars );
                $ctx->stash( 'entry', $inside_mt_entry );
            }
            $ctx->stash( '__related_entries_counter', $counter );
            if ( $counter > 1 ) {
                return $content;
            }
        }
    }
    function smarty_block_mt_multiplefield ( $args, $content, &$ctx, &$repeat ) {
        $localvars = array( 'raw_value', 'field_value', '__field_counter', '__field_length' );
        if (! isset( $content ) ) {
            $ctx->localize( $localvars );
            $this_tag = $ctx->this_tag();
            if (! $this_tag ) return;
            $this_tag = strtolower( $this_tag );
            $this_tag = preg_replace( '/^mt/i', '', $this_tag );
            $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
            $value = preg_replace( '/^,/', '', $value );
            $value = preg_replace( '/,$/', '', $value );
            if (! $value ) {
                $repeat = FALSE;
                return '';
            }
            $ctx->stash( 'raw_value', $value );
            $field_value = explode( ',', $value );
            $ctx->stash( 'field_value', $field_value );
            $ctx->stash( '__field_counter', 0 );
            $ctx->stash( '__field_length', count( $field_value ) );
            $repeat = TRUE;
        } else {
            $field_value = $ctx->stash( 'field_value' );
            $counter = $ctx->stash( '__field_counter' );
            $length = $ctx->stash( '__field_length' );
            if ( $args[ 'raw' ] ) {
                $ctx->restore( $localvars );
                $repeat = FALSE;
                return $ctx->stash( 'raw_value' );
            }
            if ( $counter < $length ) {
                $ctx->__stash[ 'vars' ][ '__value__' ] = $field_value[ $counter ];
                $counter++;
                $ctx->__stash[ 'vars' ][ '__counter__' ] = $counter;
                $ctx->__stash[ 'vars' ][ '__odd__' ]     = ( $counter % 2 ) == 1;
                $ctx->__stash[ 'vars' ][ '__even__' ]    = ( $counter % 2 ) == 0;
                $ctx->__stash[ 'vars' ][ '__first__' ]   = $counter == 1;
                $ctx->__stash[ 'vars' ][ '__last__' ]    = ( $counter == $length );
                $repeat = TRUE;
            } else {
                $counter++;
                $repeat = FALSE;
                $ctx->restore( $localvars );
            }
            $ctx->stash( '__field_counter', $counter );
            if ( $counter > 1 ) {
                if ( isset( $args[ 'glue' ] ) && ( $counter > 2 ) && !empty( $content ) )
                    $content = $args[ 'glue' ] . $content;
                return $content;
            }
        }
    }
    function customfield_html_dropdown_multi ( &$ctx, $param ) {
        extract( $param );
        require_once( 'MTUtil.php' );
        $field_name = encode_html( $field_name );
        $field_value = encode_html( $field_value );
        $raw_value = $field_value;
        $field_value = preg_replace( '/^,/', '', $field_value );
        $field_value = preg_replace( '/,$/', '', $field_value );
        $options = explode( ',', $field_options );
        $values = explode( ',', $field_value );
        $size = $ctx->mt->config( 'MultipleDropDownSize' );
        if (! $size ) $size = 4;
        $res = "<div><input type=\"hidden\" name=\"{$field_name}\" id=\"{$field_name}\" value=\"{$raw_value}\" />";
        $res .= "<select name=\"{$field_name}\" multiple=\"multiple\" size=\"{$size}\" onchange=\"script_field_html_dd( this, '{$field_name}' );\">";
        foreach ( $options as $option ) {
            $selected;
            if ( in_array( $option, $values ) ) {
                $selected = ' selected="selected"';
            }
            $field = "<option value=\"{$option}\"{$selected}>$option</option>";
            $res .= $field;
        }
        $res .= "</select></div>";
        if (! $ctx->stash( 'send_customfield_html_dropdown_multi' ) ) {
            $res .= <<<EOT

<script type="text/javascript">
    function script_field_html_dd( dropdown, basename ) {
        var field_array = new Array();
        var vals;
        for ( var i = 0 ; i < dropdown.length; i++ ) {
            if ( dropdown[i].selected ) {
                field_array.push( dropdown[i].value );
            }
        }
        vals = field_array.join( ',' );
        vals = ',' + vals + ',';
        document.getElementById( basename ).value = vals;
    }
</script>
EOT;
        }
        $ctx->stash( 'send_customfield_html_dropdown_multi', 1 );
        return $res;
    }
    function customfield_html_checkbox_multi ( &$ctx, $param ) {
        extract( $param );
        require_once( 'MTUtil.php' );
        $field_name = encode_html( $field_name );
        $field_value = encode_html( $field_value );
        $raw_value = $field_value;
        $field_value = preg_replace( '/^,/', '', $field_value );
        $field_value = preg_replace( '/,$/', '', $field_value );
        $options = explode( ',', $field_options );
        $values = explode( ',', $field_value );
        $count = count( $options );
        $res = "<div><input type=\"hidden\" name=\"{$field_name}\" id=\"{$field_name}\" value=\"{$raw_value}\" />";
        $i = 1;
        foreach ( $options as $option ) {
            $checked;
            if ( in_array( $option, $values ) ) {
                $checked = ' checked="checked"';
            }
            $field = "<label><input id=\"{$field_name}-{$i}\" onchange=\"script_field_html_cb( this, '{$field_name}', {$count} );\" type=\"checkbox\" name=\"{$field_name}\" value=\"{$option}\" /> {$option}</label>";
            $res .= $field;
            $i++;
        }
        $res .= "</div>";
        if (! $ctx->stash( 'send_customfield_html_checkbox_multi' ) ) {
            $res .= <<<EOT

<script type="text/javascript">
    function script_field_html_cb( input, basename, count ) {
        var field_array = new Array();
        var vals;
        for ( i = 1; i <= count; i++ ) {
            var ele = document.getElementById( basename + '-' + i );
            if ( ele.checked ) {
                field_array.push( ele.value );
            }
        }
        vals = field_array.join( ',' );
        vals = ',' + vals + ',';
        document.getElementById( basename ).value = vals;
    }
</script>
EOT;
        }
        $ctx->stash( 'send_customfield_html_checkbox_multi', 1 );
        return $res;
    }
?>