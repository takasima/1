<?php
function smarty_block_mtcustomobjectcolumns( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'customobject', 'customobject_column_names', 'customobject_column_name', 'customobject_column_value', '_customobject_column_names_counter',
                        'blog', 'blog_id' );
    // $app = $ctx->stash( 'bootstrapper' );
    include_once( 'customobject.util.php' );
    $_customobject = new CustomObject;
    $prefix = __init_customobject_class( $ctx );
    $id = $args[ 'id' ];
    if ( $id ) {
        $class = $args[ 'class' ] ? $args[ 'class' ] : 'customobject';
        $customobject = $_customobject->Find( "{$prefix}_id = $id AND {$prefix}_class = $class", false, false );
    } else {
        $customobject = $ctx->stash( 'customobject' );
    }
    if (! isset( $content ) ) {
        if ( ! count( $customobject ) ) {
            $ctx->restore( $localvars );
            $repeat = FALSE;
            return '';
        }
        $blog_id = $customobject->blog_id;
        $blog = $ctx->mt->db()->fetch_blog( $blog_id );
        $column_names = $customobject->GetAttributeNames();
        $ctx->stash( 'customobject_column_names', $column_names );
        $counter = 0;
    } else {
        $column_names = $ctx->stash( 'customobject_column_names' );
        $counter = $ctx->stash( '_customobject_column_names_counter' );
    }
    if ( $counter < count( $column_names ) ) {
        $ctx->stash( 'blog', $blog );
        $ctx->stash( 'blog_id', $blog_id );
        $column_name = $column_names[ $counter ];
        $column_value = $customobject->$column_name;
        $column_name = preg_replace( "/^{$prefix}_/", '', $column_name );
        $ctx->stash( 'customobject_column_name', $column_name );
        $ctx->stash( 'customobject_column_value', $column_value );
        $ctx->stash( 'customobject', $customobject );
        $ctx->stash( '_customobject_column_names_counter', $counter + 1 );
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $column_names ) );
        $repeat = TRUE;
    } else {
        $ctx->restore( $localvars );
        $repeat = FALSE;
    }
    return $content;
}
?>