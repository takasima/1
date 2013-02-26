<?php
function smarty_function_mtmembersgetsessionid ( $args, &$ctx ) {
    if ( $args[ 'dynamic' ] ) {
        $param = getenv('REDIRECT_QUERY_STRING');
        if (preg_match('/IIS/', $_SERVER['SERVER_SOFTWARE'])) {
            $param = $_SERVER['QUERY_STRING'];
        }
        parse_str($param);
    } else {
        $sess_id = $_REQUEST['sess_id'];
    }
    if ( $sess_id ) {
        return $sess_id;
    }
    return '';
}
?>
