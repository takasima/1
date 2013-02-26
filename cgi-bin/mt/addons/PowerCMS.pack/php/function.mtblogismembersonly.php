<?php
function smarty_function_mtblogismembersonly ( $args, &$ctx ) {
    $blog = $ctx->stash( 'blog' );
    if( $blog->has_column('is_members') ){
        if ( $blog->is_members ) {
            return 1;
        }
    }
    return 0;
}
?>
