<?php
function smarty_function_mtextfieldmultivalue ( $args, &$ctx ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $multiple = $extfield->extfields_multiple;
        if ( $multiple ) {
            $text = $extfield->extfields_text;
            $type = $extfield->extfields_type;
            $glue = $args[ 'glue' ];
            $active = $args[ 'active' ];
            if ( isset( $glue ) ) {
                $multiples = preg_split( "/,/", $multiple );
                $actives = preg_split( "/,/", $text );
                array( $res );
                foreach ( $multiples as $item ) {
                    if ( $active && $type == 'cbgroup' ) {
                        $search = preg_quote( $item, '/' );
                        if ( preg_grep ( "/^$search$/", $actives ) ) {
                            $res[] = $item;
                        }
                    } else {
                        if ( $active && $type != 'cbgroup' ) {
                            return $text;
                        }
                        $res[] = $item;
                    }
                }
                return $res ? join( $glue, $res ) : '';
            } else {
                return $value;
            }
        }
    }
    return '';
}
?>