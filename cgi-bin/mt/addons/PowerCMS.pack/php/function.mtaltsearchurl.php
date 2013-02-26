<?php
function smarty_function_mtaltsearchurl ( $args, $ctx ) {
    $url = getenv( 'REQUEST_URI' );
    $url = preg_split( "/\?/", $url );
    return htmlspecialchars( $url[0] );
}
?>