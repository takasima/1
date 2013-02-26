<?php
function get_extfield ( $args, &$ctx ) {
    $entry_id  = NULL;
    $stash_key = NULL;
    $label     = NULL;
    $entry = $ctx->stash( 'entry' );
    if ( $entry ) {
        $entry_id = $entry->entry_id;
    } else {
        return NULL;
    }
    $extfield = NULL;
    $extfield = $ctx->stash( 'extfield' );
    $label = $args[ 'label' ];
    if ( $label ) {
        $label = $ctx->mt->db()->escape( $label );
        $hash = md5( $label );
        $stash_key = "extfield-$entry_id-$hash";
    }
    if ( (! isset( $extfield ) ) && $label ) {
        if ( $ctx->stash( $stash_key ) ) {
            return $ctx->stash( $stash_key );
        }
        require_once "class.mt_extfields.php";
        $_ext = new ExtFields;
        $where = "extfields_entry_id = {$entry_id}"
               . " AND extfields_label = '{$label}'"
               . " AND extfields_status = 1 ";
        $extra = array(
            'limit'  => 1,
            'offset' => 0,
        );
        $results = $_ext->Find( $where, false, false, $extra );
        if ( count( $results ) ) {
            $extfield = $results[ 0 ];
        }
    }
    if ( isset( $extfield ) ) {
        $ctx->stash( $stash_key, $extfield );
    }
    return $extfield;
}
?>