<?php
function smarty_block_mtcampaignasset( $args, $content, &$ctx, &$repeat ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $class = $args[ 'class' ];
        if (! isset( $class ) ) {
            $class = $args[ 'type' ];
            if (! isset( $class ) ) {
                $class = 'image';
            }
        }
        if ( $class == 'image' ) {
            $asset_id = $campaign->image_id;
        } else { 
            $asset_id = $campaign->movie_id;
        }
        if ( isset( $asset_id ) ) {
            $asset = $ctx->mt->db()->fetch_assets( array( 'id' => $asset_id ) );
            if ( isset( $asset ) ) {
                if ( count( $asset ) == 1 ) {
                    $asset = $asset[0];
                    $ctx->stash( 'asset', $asset );
                }
            }
        } else {
            $repeat = FALSE;
            return '';
        }
    }
    return $content;
}
?>