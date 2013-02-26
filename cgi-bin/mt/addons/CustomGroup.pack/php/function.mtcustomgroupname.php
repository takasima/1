<?php
function smarty_function_mtcustomgroupname( $args, $ctx ) {
    $name = $ctx->stash( 'customgroup_name' );
    if ( $name ) {
        return $name;
    }
    $class = $ctx->stash( 'customgroup_class' );
    $group_id = $ctx->stash( 'customgroup_id' );
    $group_prefix = 'customgroup';
    require_once( 'class.mt_customgroup.php' );
    $_sort = new CustomGroup;
    $where = "{$group_prefix}_id=$group_id";
    $results = $_sort->Find( $where );
    if ( count( $results ) ) {
        return $results[0]->customgroup_name;
    }
}
?>