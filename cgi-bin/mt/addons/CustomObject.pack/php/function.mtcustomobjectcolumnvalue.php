<?php
function smarty_function_mtcustomobjectcolumnvalue ( $args, &$ctx ) {
    return $ctx->stash( 'customobject_column_value' );
}
?>