<?php
function smarty_function_mtextfielddescription ( $args, &$ctx ) {
    require_once ( 'format_text.php' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $text  = $extfield->extfields_description;
        $trans = $extfield->extfields_transform;
        $text  = format_text( $trans, $text );
        return $text;
    }
    return '';
}
?>