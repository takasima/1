<?php
function smarty_block_mtifextfieldcompare ( $args, $content, &$ctx, $repeat ) {
    $c_label = $args[ 'label' ];
    $c_text  = $args[ 'text' ];
    $extfield = $ctx->stash( 'extfield' );
    if (! isset ( $extfield ) ) {
        require_once ( 'extfield.util.php' );
        $extfield  = get_extfield( $args, $ctx );
    }
    $text  = $extfield->extfields_text;
    $label = $extfield->extfields_label;
    if ( ( $c_label ) && ( $c_text ) ) {
        if ( ( $c_label == $label ) && ( $c_text == $text ) ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    } else {
        if ($c_label) {
            if ( $c_label == $label ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        } elseif ( $c_text ) {
            if ( $c_text == $text ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
            }
        }
    }
}
?>