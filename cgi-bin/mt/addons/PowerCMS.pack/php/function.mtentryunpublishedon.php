<?php
function smarty_function_mtentryunpublishedon ( $args, &$ctx ) {
    $format = $args[ 'format' ];
    $blog = $ctx->stash( 'blog' );
    $entry = $ctx->stash( 'entry' );
    if ( $entry ) {
        $entry_unpublished_on = $entry->entry_unpublished_on;
    } else {
        return $ctx->error( "No entry available" );
    }
    $entry_unpublished_on = str_replace( ' ', '', $entry_unpublished_on );
    $entry_unpublished_on = str_replace( ':', '', $entry_unpublished_on );
    $entry_unpublished_on = str_replace( '-', '', $entry_unpublished_on );
    $text = format_ts( $format, $entry_unpublished_on, $blog, isset( $args[ 'language' ] ) ? $args[ 'language' ] : null );
    return $text;
}
?>