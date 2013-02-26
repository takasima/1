<?php require_once 'emoji_docomo2docomo_legacy.php';
function get_docomo_regacy() { // Backcompat
  $f = 'get_docomo_legacy';
  if ( function_exists( $f ) ) {
    $args = func_get_args();
    return call_user_func_array( $f, $args );
  }
}
?>