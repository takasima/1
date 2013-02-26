<?php
function smarty_function_mtformelementcolumn ( $args, &$ctx ) {
    $contactform = $ctx->stash( 'contactform' );
    $column = $args[ column ];
    if ( isset( $contactform ) ) {
        if (! $contactform->has_column( $column ) ) {
            return '';
        }
    }
    if ( isset( $contactform ) && $contactform->$column ) {
        if ( preg_match( "/_on$/", $column ) ) {
            $args[ 'ts' ] = $contactform->$column;
            return $ctx->_hdlr_date( $args, $ctx );
        } else {
            return $contactform->$column;
        }
    } else {
        return '';
    }
    return '';
}
?>