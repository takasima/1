<?php
function smarty_function_mtcontactformfieldscope ( $args, &$ctx ) {
    return $ctx->mt->config( 'ContactFormFieldScope' ) ? $ctx->mt->config( 'ContactFormFieldScope' ) : 'blog' ;
}
?>