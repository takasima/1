<?php
function smarty_function_mtxmldocument($args, &$ctx) {

    $charset = $ctx->mt->config( 'PublishCharset' );
    return '<?xml version="1.0" encoding="' . $charset . '"?>';


}
?>