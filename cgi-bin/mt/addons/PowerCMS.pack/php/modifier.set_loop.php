<?php
function smarty_modifier_set_loop( $text, $name ) {
    $args = func_get_args();
    $sep  = $args[ 2 ];
    $func = $args[ 3 ]; # so MT(5.03) bug, cannot get now.
    if ( ! $sep ) { // FIXME: 0 -> 0, "" -> /(?:)/
        $sep = ',';
    }
    $array = preg_split( "/$sep/", $text );
    $mt = MT::get_instance();
    $ctx =& $mt->context();
    $key = '__inside_set_hashvar';
    if ( !array_key_exists( $key, $ctx->__stash ) ) {
        $key = 'vars';
    }
    $vars =& $ctx->__stash[ $key ];
    $vars[ $name ] = $array;
    return '';
}
?>
