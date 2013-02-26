<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_block_mtifentryrecommended($args, $content, &$ctx, &$repeat) {
    $localvars = array('cp_if_recommended', 'cp_if_recommended_else');
    if (!isset($content)) {
        $ctx->localize(array('_ifrc_counter', 'conditional','else_content'));
        $ctx->stash('_ifrc_counter', 0);
        $ctx->stash('cp_if_recommended_else', 1);
    }
    else {
        $counter = $ctx->stash('_ifrc_counter');
        if ($counter < 1) {
            $repeat = true;
            $false_block = $ctx->stash('else_content');
            $ctx->stash('_ifrc_false_block', $false_block);
            $ctx->stash('_ifrc_counter', $counter + 1);
            $ctx->stash('conditional', 1);
            $ctx->__stash['cp_if_recommended_else'] = null;
            $ctx->stash('cp_if_recommended', '1');
            return '';
        } else {
            $ctx->restore(array('_ifrc_counter', 'conditional','else_content'));
            $repeat = false;
        }

        $false_block = $ctx->stash('_ifrc_false_block');
        $true_block = $content;
        $ctx->__stash['cp_if_recommended'] = null;
        $ctx->__stash['_ifrc_false_block'] = null;

        $entry = $ctx->stash('entry');
        if (!isset($entry)) {
            return $ctx->error('No entry available.');
        }

        $class = $args['class'];
        if (!$class) {
            $class = 'scored';
        }
        if ($class) {
            require_once("MTUtil.php");
            $class = strip_tags($class);
            $class = ' class="' . $class . '"';
        }
        $class_else = $args['class_else'];
        if (!$class_else) {
            $class_else = 'scored-else';
        }
        if ($class_else) {
            require_once("MTUtil.php");
            $class_else = strip_tags($class_else);
            $class_else = ' class="' . $class_else . '"';
        }

        require_once "function.mtstaticwebpath.php";
        $static_path = smarty_function_mtstaticwebpath($args, $ctx);
        require_once "function.mtcgipath.php";
        $cgi_path = smarty_function_mtcgipath($args, $ctx);

        $entry_id    = $entry->entry_id;
        $blog_id     = $entry->entry_blog_id;

        $script = "
<script type=\"text/javascript\" src=\"${static_path}mt.js\"></script>
<script type=\"text/javascript\" src=\"${static_path}js/tc.js\"></script>
<script type=\"text/javascript\" src=\"${static_path}js/tc/client.js\"></script>
<script type=\"text/javascript\">
function scoredby_script_vote(id) {
    TC.Client.call({
        'load': function(c, result) { eval(result); },
        'method': 'POST',
        'uri': '${cgi_path}mt-cp.cgi',
        'arguments': {
            '__mode': 'vote',
            'blog_id': '$blog_id',
            'id': id,
            'f': 'scored,sum',
            'jsonp': 'scoredby_script_callback'
        }
    });
}
function scoredby_script_callback(scores_hash) {
    var true_block = getByID('scored_' + $entry_id);
    var false_block = getByID('scored_' + $entry_id + '_else');
    var span;
    if (scores_hash['$entry_id'] && scores_hash['$entry_id'].scored) {
        span = getByID('cp_total_' + $entry_id);
        if (true_block)
            true_block.style.display = '';
        if (false_block) 
            false_block.style.display = 'none';
    }
    else {
        span = getByID('cp_total_' + $entry_id + '_else');
        if (true_block)
            true_block.style.display = 'none';
        if (false_block) 
            false_block.style.display = '';
    }
    if (span) {
        if (scores_hash['$entry_id'] && scores_hash['$entry_id'].sum)
            span.innerHTML = scores_hash['$entry_id'].sum;
        else
            span.innerHTML = 0;
    }
}
</script>";

        $out = "
$script
<div id=\"scored_$entry_id\"$class style=\"display:none\">
    $true_block
</div>
<div id=\"scored_${entry_id}_else\"$class_else style=\"display:none\">
    $false_block
</div>
<script type=\"text/javascript\" src=\"${cgi_path}mt-cp.cgi?__mode=score&blog_id=$blog_id&id=$entry_id&f=scored,sum&jsonp=scoredby_script_callback\"></script>";

        return $out;
    }
}
?>
