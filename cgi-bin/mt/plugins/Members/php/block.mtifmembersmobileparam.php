<?php
function smarty_block_mtifmembersmobileparam($args, $content, &$ctx, &$repeat) {
    $param = getenv('REDIRECT_QUERY_STRING');
    if (preg_match('/IIS/', $_SERVER['SERVER_SOFTWARE'])) {
        $param = $_SERVER['QUERY_STRING'];
    }
    parse_str($param);
    if ( $mobile ) {
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat, 1);
    }
    return $ctx->_hdlr_if($args, $content, $ctx, $repeat, 0);
}
?>
