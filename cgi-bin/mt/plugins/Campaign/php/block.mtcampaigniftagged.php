<?php
function smarty_block_mtcampaigniftagged( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $campaign = $ctx->stash( 'campaign' );
        if ( $campaign ) {
            $campaign_id = $campaign->campaign_id;
            $tag = $args[ 'name' ];
            $tag or $tag = $args[ 'tag' ];
            $targs = array( 'campaign_id' => $campaign_id );
            if ( $tag && ( substr( $tag, 0, 1 ) == '@' ) ) {
                $targs[ 'include_private' ] = 1;
            }
            require_once( 'block.mtcampaigntags.php' );
            $tags = fetch_campaign_tags( $ctx, $targs );
            if ( $tag && $tags ) {
                $has_tag = 0;
                foreach ( $tags as $row ) {
                    $row_tag = $row->tag_name;
                    if ( $row_tag == $tag ) {
                        $has_tag = 1;
                        break;
                    }
                }
            } else {
                $has_tag = count( $tags ) > 0;
            }
        }
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, $has_tag );
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>
