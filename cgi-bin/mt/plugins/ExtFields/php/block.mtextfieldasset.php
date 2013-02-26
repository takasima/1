<?php
function smarty_block_mtextfieldasset( $args, $content, &$ctx, &$repeat ) {
    require_once ( 'extfield.util.php' );
    $localvars = array( 'asset' );
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $asset = $ctx->stash( 'asset' );
        if ( $asset ) {
            $ctx->stash( 'asset', $asset );
        } else {
            if ( $label = $args[ 'label' ] ) {
                $hash = md5( $label );
                $entry = $ctx->stash( 'entry' );
                $entry_id = $entry->entry_id;
                $asset_stash_key_by_label = "extfield-$entry_id-asset-$hash";
                if ( $ctx->stash( $asset_stash_key_by_label ) ) {
                    $asset = $ctx->stash( $asset_stash_key_by_label );
                } else {
                    $extfield = get_extfield( $args, $ctx );
                    if ( isset ( $extfield ) ) {
                        $asset_id = $extfield->extfields_asset_id;
                        if ( $asset_id ) {
                            $results = $ctx->mt->db()->fetch_assets( array( 'id' => $asset_id ) );
                            if ( count( $results ) == 1 ) {
                                $asset = $results[ 0 ];
                            }
                        }
                    }
                }
                $ctx->stash( 'asset', $asset );
                if ( isset( $asset ) ) {
                    $ctx->stash( $asset_stash_key_by_label, $asset );
                    $asset_id = $asset->asset_id;
                    $asset_cache_key = "powercms-asset-cache-$asset_id";
                    $ctx->stash( $asset_cache_key, $asset );
                }
            }
        }
    } else {
        if (! $ctx->stash( 'asset' ) ) {
            $content = NULL;
        }
        $ctx->restore( $localvars );
    }
    return $content;
}
?>