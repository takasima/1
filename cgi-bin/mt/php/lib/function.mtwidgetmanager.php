<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

require_once("function.mtinclude.php");
function smarty_function_mtwidgetmanager($args, &$ctx) {
    $blog_id = $args['blog_id'];
    $blog_id or $blog_id = $ctx->stash('blog_id');
    $blog_id or $blog_id = 0;
    $widgetmanager = $args['name']; // Should we try to load is there's only one?
    if (!$widgetmanager) 
        return;

    $tmpl = $ctx->mt->db()->get_template_text($ctx, $widgetmanager, $blog_id, 'widgetset', $args['global']);
    if ( !isset($tmpl) || !$tmpl ) {
        return '';
    }
    if ( isset($tmpl) && $tmpl ) {
        // push to ctx->vars
        $ext_args = array();
        while(list ($key, $val) = each($args)) {
            if (!preg_match('/(^name$|^blog_id$)/', $key)) {
                require_once("function.mtsetvar.php");
                smarty_function_mtsetvar(array('name' => $key, 'value' => $val), $ctx);
                $ext_args[] = $key;
            }
        }
        if ($ctx->_compile_source('evaluated template', $tmpl, $_var_compiled)) {
            ob_start();
            $ctx->_eval('?>' . $_var_compiled);
            $_contents = ob_get_contents();
            ob_end_clean();
            _clear_vars($ctx, $ext_args);
            return $_contents;
        }
        else {
            _clear_vars($ctx, $ext_args);
            return $ctx->error($ctx->mt->translate('Error compiling widgetset [_1]', $widgetmanager));
        }
    }
    return '';
}
?>
