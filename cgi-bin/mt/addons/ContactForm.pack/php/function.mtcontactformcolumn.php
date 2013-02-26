<?php
function smarty_function_mtcontactformcolumn ( $args, &$ctx ) {
    $contactformgroup = $ctx->stash( 'contactformgroup' );
    $column = $args[ column ];
    if ( isset( $contactformgroup ) ) {
        if (! $contactformgroup->has_column( $column ) ) {
            return '';
        }
    }
    if ( isset( $contactformgroup ) && $contactformgroup->$column ) {
        if ( preg_match( "/_on$/", $column ) ) {
            $args[ 'ts' ] = $customobject->$column;
            return $ctx->_hdlr_date( $args, $ctx );
        } else {
            return $contactformgroup->$column;
        }
    } else {
        return '';
    }
    return '';
}
?>