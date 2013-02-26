<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_block_mtifloggedin($args, $content, &$ctx, &$repeat) {
    $localvars = array('cp_if_loggedin', 'cp_if_loggedin_else');
    if (!isset($content)) {
        $ctx->localize(array('_iflg_counter', 'conditional','else_content'));
        $ctx->stash('_iflg_counter', 0);
        $ctx->stash('cp_if_loggedin_else', 1);
    }
    else {
        $counter = $ctx->stash('_iflg_counter');
        if ($counter < 1) {
            $repeat = true;
            $false_block = $ctx->stash('else_content');
            $ctx->stash('_iflg_false_block', $false_block);
            $ctx->stash('_iflg_counter', $counter + 1);
            $ctx->stash('conditional', 1);
            $ctx->__stash['cp_if_loggedin_else'] = null;
            $ctx->stash('cp_if_loggedin', '1');
            return '';
        } else {
            $ctx->restore(array('_iflg_counter', 'conditional','else_content'));
            $repeat = false;
        }

        $false_block = $ctx->stash('_iflg_false_block');
        $true_block = $content;
        $ctx->__stash['cp_if_loggedin'] = null;
        $ctx->__stash['_iflg_false_block'] = null;

        $elem_id = 'logged_in';
        if (isset($args['element_id']))
            $elem_id = $args['element_id'];
        if ($elem_id) {
            require_once("MTUtil.php");
            $class_else = strip_tags($class_else);
        }

        $class = 'logged-in';
        if (isset($args['class']))
            $class = $args['class'];
        if ($class) {
            require_once("MTUtil.php");
            $class = strip_tags($class);
            $class = ' class="' . $class . '"';
        }

        $class_else = 'logged-in-else';
        if (isset($args['class_else']))
            $class_else = $args['class_else'];
        if ($class_else) {
            require_once("MTUtil.php");
            $class_else = strip_tags($class_else);
            $class_else = ' class="' . $class_else . '"';
        }

        require_once "function.mtcgipath.php";
        $cgipath = smarty_function_mtcgipath($args, $ctx);
        require_once "function.mtcgihost.php";
        $cgihost = smarty_function_mtcgihost($args, $ctx);
        require_once "function.mtbloghost.php";
        $bloghost = smarty_function_mtbloghost($args, $ctx);
        $cpscript = $ctx->mt->config('CommunityScript');
        $names_script_block = $cgihost === $bloghost
            ? "commenter_name = getCookie('commenter_name');\nuser_name = getCookie('mt_user');"
            : "document.write('<script src=\"$cgipath$cpscript?__mode=loggedin_js\"></scr' + 'ipt>');";

        $script_block = "";
        $script = "";
        if (isset($args['script']))
            $script = $args['script'];
        if ($script) {
            $script_block = "
<script type=\"text/javascript\">
var is_loggedin = false;
if ( typeof(mtGetUser) == 'undefined' )
    is_loggedin = user ? true : false;
else {
    var u = mtGetUser();
    is_loggedin = u && u.name ? true : false;
}
$script(is_loggedin ? 1 : 0, '$elem_id');
</script>";
        }

        $out = "
<div id=\"$elem_id\"$arg_class style=\"display:none\" class=\"inline\">
$true_block
</div>
<div id=\"${elem_id}_else\"$arg_class_else style=\"display:none\" class=\"inline\">
$false_block
</div>
$script_block";
        return $out;
    }
}
?>
