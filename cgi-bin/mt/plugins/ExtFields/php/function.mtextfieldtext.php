<?php
function smarty_function_mtextfieldtext ( $args, &$ctx ) {
    require_once( 'format_text.php' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    $format = $args[ 'format' ];
    $blog = $ctx->stash( 'blog' );
    if ( isset( $extfield ) ) {
        $text  = $extfield->extfields_text;
        $type  = $extfield->extfields_type;
        $trans = $extfield->extfields_transform;
        if ( $type == 'date' ) {
            require_once( "MTUtil.php" );
            $text = format_ts( $format, $text, $blog, isset( $args[ 'language' ] ) ? $args[ 'language' ] : NULL );
            return $text;
        } else if ( $type == 'textarea' ) {
            $text = format_text( $trans, $text );
            return $text;
        } else {
            return $text;
        }
    }
    return '';
}
?>