<?php
function smarty_function_mtformelementhtml ( $args, &$ctx ) {
    $old_vars = $ctx->__stash[ 'vars' ];
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $contactform = $ctx->stash( 'contactform' );
    $mtml = '';
    if ( $contactform ) {
        require_once( 'modifier.mteval.php' );
        $mtml = $contactform->mtml;
        $type = $contactform->type;
        $basename = $contactform->basename;
        $ctx->__stash[ 'vars' ][ 'field_basename' ] = $basename;
        $ctx->__stash[ 'vars' ][ 'field_name' ] = $contactform->name;
        $ctx->__stash[ 'vars' ][ 'field_required' ] = $contactform->required;
        $ctx->__stash[ 'vars' ][ 'field_description' ] = $contactform->field_description;
        $ctx->__stash[ 'vars' ][ 'field_option' ] = $contactform->field_option;
        $ctx->__stash[ 'vars' ][ 'field_size' ] = $contactform->size;
        $option = $contactform->options;
        $default = $contactform->default;
        if ( isset( $old_vars[ "__contactform_{$basename}__" ] ) ) {
            $default = $old_vars[ "__contactform_{$basename}__" ];
        }
        $ctx->__stash[ 'vars' ][ 'field_default' ] = $default;
        $options = preg_split( "/,/", $option );
        $defauld_vals;
        if ( $default ) {
            $defauld_vals = preg_split( "/,/", $default );
        }
        $field_loop = array();
        $i = 1;
        foreach ( $options as $opt ) {
            $option_default;
            $first;
            $last;
            if ( $opt == $default ) {
                $option_default = 1;
            }
            if ( $defauld_vals && preg_grep( "/^$opt$/", $defauld_vals ) ) {
                $option_default = 1;
            }
            if ( $i == 1 ) {
                $first = 1;
            }
            if ( $i == count( $options ) ) {
                $last = 1;
            }
            array_push ( $field_loop, array( 
                'option_value' => $opt,
                'option_default' => $option_default,
                '__first__'  => $first,
                '__last__'  => $last,
            ) );
            $i++;
        }
        $ctx->__stash[ 'vars' ][ 'field_loop' ] = $field_loop;
        $mtml = smarty_modifier_mteval( $mtml, 1 );
    }
    $ctx->__stash[ 'vars' ] = $old_vars;
    return $mtml;
}
?>