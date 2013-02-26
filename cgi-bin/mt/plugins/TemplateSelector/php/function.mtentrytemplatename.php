<?php
function smarty_function_mtentrytemplatename ( $args, &$ctx ) {
    $entry = $ctx->stash( 'entry' );
    if ( $entry ) {
        $template_id = $entry->entry_template_module_id;
    } else {
        return $ctx->error( "No entry available" );
    }
    if ( $template_id ) {
        require_once "class.mt_template.php";
        $_template = new Template;
        $where = "template_id={$template_id}"
        $extra = array(
            'limit'  => 1,
            'offset' => 0,
        );
        $results = $_template->Find( $where, false, false, $extra );
        if ( count( $results ) ) {
            return $results[0]->template_name;
        }
    }
    return '';
}
?>