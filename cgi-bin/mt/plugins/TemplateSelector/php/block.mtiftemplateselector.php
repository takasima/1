<?php
function smarty_block_mtiftemplateselector ( $args, $content, $ctx, $repeat ) {
    $name  = $args[ 'name' ];
    $entry = $ctx->stash( 'entry' );
    if ( $entry ) {
        $entry_id  = $entry->entry_id;
        $module_id = $entry->entry_template_module_id;
    } else {
        return $ctx->error( "No entry available" );
    }
    require_once 'class.mt_template.php';
    $_template = new Template;
    $where = "template_id = {$module_id}";
    $extra = array(
        'limit'  => 1,
        'offset' => 0,
    );
    $results = $_template->Find( $where, false, false, $extra );
    if ( count( $results ) && $name != "" ) {
        $template = $results[0];
        if ( $name == $template->template_name ) {
            return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
        }
    } elseif ( $name == '' ) {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 1 );
    }
    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, 0 );
}
?>