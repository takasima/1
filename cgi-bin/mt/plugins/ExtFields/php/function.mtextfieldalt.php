<?php
function smarty_function_mtextfieldalt ( $args, &$ctx ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        return $extfield->extfields_alternative;
    }
    return '';
}
?>