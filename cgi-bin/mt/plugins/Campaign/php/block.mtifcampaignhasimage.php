<?php
function smarty_block_mtifcampaignhasimage ($args, $content, &$ctx, &$repeat) {
    if (isset($content)) {
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat);
    }

    $campaign = $ctx->stash('campaign');
    if (!isset($campaign)) {
        return $ctx->error();
    }

    $asset_id = $campaign->image_id;
    if (isset($asset_id)) {
        $asset = $ctx->mt->db()->fetch_assets(array('id' => $asset_id));
        if (isset($asset)) {
            if (count($asset) == 1) {
                return $ctx->_hdlr_if($args, $content, $ctx, $repeat, true);
            }
        }
    }
    return $ctx->_hdlr_if($args, $content, $ctx, $repeat, false);
}
