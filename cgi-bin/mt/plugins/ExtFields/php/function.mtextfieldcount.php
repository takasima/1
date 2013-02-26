<?php
function smarty_function_mtextfieldcount ( $args, &$ctx ) {
    $extfields_count = $ctx->stash( 'extfields_count' );
    if ( $extfields_count ) {
        return $extfields_count;
    } else {
        $entry = $ctx->stash( 'entry' );
        if ( $entry ) {
            $entry_id = $entry->entry_id;
        } else {
            return $ctx->error( "No entry available" );
        }
        require_once "class.mt_extfields.php";
        $_ext = new ExtFields;
        $where = "extfields_entry_id = {$entry_id} "
               . " AND extfields_status = 1 "
               . " ORDER BY extfields_sort_num ASC";
        $extfields = $_ext->Find( $where );
        $count = count( $extfields );
        $ctx->stash( 'extfields_count', $count );
        return $count;
    }
}
?>