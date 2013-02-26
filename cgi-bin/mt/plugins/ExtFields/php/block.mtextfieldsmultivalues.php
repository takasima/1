<?php
function smarty_block_mtextfieldsmultivalues ( $args, $content, &$ctx, &$repeat ) {
    require_once ( 'extfield.util.php' );
    if (! isset( $content ) ) {
        $i = 1;
        $extfield  = get_extfield( $args, $ctx );
        $multiple  = $extfield->extfields_multiple;
        $text      = $extfield->extfields_text;
        $type      = $extfield->extfields_type;
        $multiples = preg_split ( '/,/', $multiple );
        $ctx->stash( 'multiple', $multiple );
        $ctx->stash( 'multiples', $multiples );
        $ctx->stash( 'actives', $actives );
        $ctx->stash( 'text', $text );
        $ctx->stash( 'type', $type );
    } else {
        $multiple  = $ctx->stash( 'multiple' );
        $multiples = $ctx->stash( 'multiples' );
        $text = $ctx->stash( 'text' );
        $type = $ctx->stash( 'type' );
        $i = $ctx->stash( 'i_value' )+ 1;
    } if ( $i <= count( $multiples ) ){
        $value = $multiples[ $i - 1 ];
        $ctx->stash( 'value', $value );
        if ( $type == 'cbgroup' ) {
            $match = strpos( $text, $value );
        } else {
            $match = false;
            if ( $value == $text ) {
                $match = true;
            }
        }
        if ( $match === false ) {
            $ctx->stash( 'selected', 0 );
        } else {
            $ctx->stash( 'selected', 1 );
        }
        $repeat = true;
    } else {
        $repeat = false;
    }
    $ctx->stash( 'i_value', $i );
    return $content;
}
?>