<?php 
function __keitailib_encode_js ( $str ) {
    if (!isset( $str ) ) return '';
    $str = preg_replace( '!\\\\!', '\\\\', $str );
    $str = preg_replace( '!>!', '\\>', $str );
    $str = preg_replace( '!<!', '\\<', $str );
    $str = preg_replace( '!(s)(cript)!i', '$1\\\\$2', $str );
    $str = preg_replace( '!</!', '<\\/', $str );
    $str = preg_replace( '!\'!', '\\\'', $str );
    $str = preg_replace( '!"!', '\\"', $str );
    $str = preg_replace( '!\n!', '\\n', $str );
    $str = preg_replace( '!\f!', '\\f', $str );
    $str = preg_replace( '!\r!', '\\r', $str );
    $str = preg_replace( '!\t!', '\\t', $str );
    return $str;
}
?>