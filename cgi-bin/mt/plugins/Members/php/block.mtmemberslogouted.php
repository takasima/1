<?php
function smarty_block_mtmemberslogouted($args, $content, &$ctx, &$repeat) {
    $logout = $_GET[ 'logout' ];
    if ( $logout ) {
        return $content;
    }
    return '';
}
?>