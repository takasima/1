<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_function_mtentryrecommendvotelink($args, &$ctx) {
    if ( $ctx->stash('cp_if_recommended_else') || $ctx->stash('cp_if_recommended') ) {
        $entry = $ctx->stash('entry');
        if (!isset($entry)) {
            return $ctx->error('No entry available.');
        }
        $class = $args['class'];
        if ($class) {
            $class = strip_tags($class);
            $class = ' class="' . $class . '"';
        }
        $text = $args['text'];
        if (!isset($text)) {
            $text = $ctx->mt->translate('Click here to recommend');
        }
        if ($text) {
            require_once("MTUtil.php");
            $class = strip_tags($class);
        }
        $entry_id = $entry->entry_id;
        return "<a href=\"javascript:void(0)\" onclick=\"scoredby_script_vote('$entry_id');\"$class>$text</a>";
    }
    return '';
}
?>
