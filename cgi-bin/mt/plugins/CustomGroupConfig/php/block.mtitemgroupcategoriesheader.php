<?php
function smarty_block_mtitemgroupcategoriesheader ( $args, $content, &$ctx, &$repeat ) {
    if ( isset( $content ) ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
    $vars =& $ctx->__stash[ 'vars' ];
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $vars[ '__first__' ] == 1 );
}
?>
