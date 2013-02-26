<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_block_mtentryiftagged($args, $content, &$ctx, &$repeat) {
    if (!isset($content)) {
        $entry = $ctx->stash('entry');
        if ($entry) {
            $entry_id = $entry->entry_id;
            $blog_id = $entry->entry_blog_id;
            $class = $args['class'];
            $tag = $args['name'];
            $tag or $tag = $args['tag'];
            $targs = array('entry_id' => $entry_id, 'blog_id' => $blog_id, 'class' => $class);
            if ($tag && (substr($tag,0,1) == '@')) {
                $targs['include_private'] = 1;
            }
            $tags = $ctx->mt->db()->fetch_entry_tags($targs);
            if ($tag && $tags) {
                $has_tag = 0;
                foreach ($tags as $row) {
                    $row_tag = $row->tag_name;
                    if ($row_tag == $tag) {
                        $has_tag = 1;
                        break;
                    }
                }
            } else {
                $has_tag = count($tags) > 0;
            }
        }
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat, $has_tag);
    } else {
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat);
    }
}
?>
