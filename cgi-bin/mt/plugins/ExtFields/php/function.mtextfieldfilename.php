<?php
function smarty_function_mtextfieldfilename ( $args, &$ctx ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $path = $extfield->extfields_text;
        $path = explode( '/', $path );
        if ( count( $path ) > 0 ) {
            return array_pop( $path );
        }
    }
    return '';
}
?>