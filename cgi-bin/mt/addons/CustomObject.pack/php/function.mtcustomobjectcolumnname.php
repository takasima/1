<?php
function smarty_function_mtcustomobjectcolumnname ( $args, &$ctx ) {
    return $ctx->stash( 'customobject_column_name' );
}
?>