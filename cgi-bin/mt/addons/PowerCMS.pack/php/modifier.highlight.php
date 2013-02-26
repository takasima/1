<?php
function smarty_modifier_highlight( $text ) {
    require_once ( 'dynamicmtml.util.php' );
    $query = get_param( 'query' );
    $query = str_replace ( '\'', '', $query );
    $q = preg_split( "'[\s,]+'", $query, -1, PREG_SPLIT_NO_EMPTY );
    $qq = array();
    foreach ( $q as $val ) {
       $qq[] = "'(" . preg_quote( $val ) . ")'i";
    }
    return preg_replace( $qq, "<strong>$1</strong>", $text );
}
?>