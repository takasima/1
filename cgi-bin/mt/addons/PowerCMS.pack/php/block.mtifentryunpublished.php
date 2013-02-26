<?php
function smarty_block_mtifentryunpublished ( $args, $content, $ctx, $repeat ) {
    $entry = $ctx->stash( 'entry' );
    $blog = $ctx->stash( 'blog' );
    if ( $entry ) {
        if ( $args[ 'checked' ] ) {
            if ( ! $entry->entry_unpublished ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
            }
        }
        $entry_unpublished_on = $entry->entry_unpublished_on;
        $entry_unpublished_on = str_replace( ' ', '', $entry_unpublished_on );
        $entry_unpublished_on = str_replace( ':', '', $entry_unpublished_on );
        $entry_unpublished_on = str_replace( '-', '', $entry_unpublished_on );
    } else {
        return $ctx->error( "No entry available" );
    }
    require_once( "MTUtil.php" );
    $ts = offset_time_list( time(), $blog );
    $ts = sprintf( "%04d%02d%02d%02d%02d%02d",
                $ts[ 5 ] + 1900, $ts[ 4 ] + 1, $ts[ 3 ], $ts[ 2 ], $ts[ 1 ], $ts[ 0 ] );
    if ( ( $entry_unpublished_on != '' ) && ( $entry_unpublished_on < $ts ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
    }
}
?>