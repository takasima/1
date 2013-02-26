<?php
$_extfield_asset_id_cache = array();
$_extfield_asset_parent_id_cache = array();
function smarty_block_mtextfields( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'extfield', '_extfields_counter', 'extfields', 'extfields_count', 'asset', 'asset_thumb', 'entry_id' );
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        $counter = 0;
    } else {
        $counter = $ctx->stash( '_extfields_counter' );
    }
    $extfields = $ctx->stash( 'extfields' );
    if (! isset( $extfields ) ) {
        $entry = $ctx->stash( 'entry' );
        if (! $entry ) {
            return $ctx->error( "No entry available" );
        }
        $entry_id = $entry->entry_id;
        $ctx->stash( 'entry_id', $entry_id );
        $sort_order = $args[ 'sort_order' ];
        $sort_order = ( $sort_order == 'descend' ) ? 'DESC' : 'ASC';
        $exclude = $args[ 'exclude_label' ];
        $excludes = preg_split( '/,/', $exclude );
        require_once 'class.mt_extfields.php';
        $_ext = new ExtFields;
        $where .= "extfields_entry_id = {$entry_id} ";
        $where .= " AND extfields_status = 1 ";
        if ( $excludes ) {
            foreach ( $excludes as $exclude_label ) {
                $where .= " AND extfields_label != '${exclude_label}' ";
            }
        }
        $where .= " ORDER BY extfields_sort_num ${sort_order} ";
        $extfields = $_ext->Find( $where );
        $ctx->stash( 'extfields_count', count( $extfields ) );
        $ctx->stash( 'extfields', $extfields );
    } else {
        $counter = $ctx->stash( '_extfields_counter' );
    }
    if ( $counter < count( $extfields ) ) {
        $extfield = $extfields[ $counter ];
        $ctx->stash( 'extfield', $extfield );
        $entry_id = $ctx->stash( 'entry_id' );
        $label = $extfield->extfields_label;
        $hash = md5( $label );
        $stash_key = "extfield-$entry_id-$hash";
        $asset_stash_key_by_label = "extfield-$entry_id-asset-$hash";
        $child_stash_key_by_label = "extfield-$entry_id-asset-child-$hash";
        $ctx->stash( $stash_key, $extfield );
        $ctx->stash( '_extfields_counter', $counter + 1 );
        $asset = null;
        $asset_thumb = null;
        if ( $extfield->extfields_type == 'file' ) {
            $asset_id = $extfield->extfields_asset_id;
            if ( $asset_id )  {
                $asset_cache_key = "powercms-asset-cache-$asset_id";
                if ( $ctx->stash( $asset_cache_key ) ) {
                    $asset = $ctx->stash( $asset_cache_key );
                } elseif ( $ctx->stash( $asset_stash_key_by_label ) ) {
                    $asset = $ctx->stash( $asset_stash_key_by_label );
                } elseif ( isset( $_extfield_asset_id_cache[ $asset_id ] ) ) {
                    $asset = $_extfield_asset_id_cache[ $asset_id ];
                } else {
                    $results = $ctx->mt->db()->fetch_assets( array( 'id' => $asset_id ) );
                    if ( count( $results ) ) {
                        $asset = $results[0];
                        $_extfield_asset_id_cache[ $asset_id ] = $asset;
                    }
                }
                if ( isset( $asset ) ) {
                    $ctx->stash( $asset_cache_key, $asset );
                    $ctx->stash( $asset_stash_key_by_label, $asset );
                    if (! isset( $args[ 'no_thumbnail' ] ) ) {
                        $child_cache_key = "powercms-asset-child-cache-$asset_id";
                        if ( $ctx->stash( $child_cache_key ) ) {
                            $asset_thumb = $ctx->stash( $child_cache_key );
                        } elseif ( $ctx->stash( $child_stash_key_by_label ) ) {
                            $asset_thumb = $ctx->stash( $child_stash_key_by_label );
                        } elseif ( isset( $_extfield_asset_parent_id_cache[ $asset_id ] ) ) {
                            $asset_thumb = $_extfield_asset_parent_id_cache[ $asset_id ];
                        } else {
                            require_once 'class.mt_asset.php';
                            $_asset = new Asset;
                            $where = "asset_parent = {$asset_id} ";
                            $extra = array(
                                'limit'  => 1,
                                'offset' => 0,
                            );
                            $results = $_asset->Find( $where, false, false, $extra );
                            if ( count( $results ) ) {
                                $results = $ctx->mt->db()->fetch_assets( array( 'id' => $results[0]->asset_id ) );
                                if ( count( $results ) ) {
                                    $asset_thumb = $results[0];
                                    $_extfield_asset_parent_id_cache[ $asset_id ] = $asset_thumb;
                                }
                            }
                        }
                        if ( isset ( $asset_thumb ) ) {
                            $ctx->stash( $child_cache_key, $asset_thumb );
                            $ctx->stash( $child_stash_key_by_label, $asset );
                        }
                    }
                }
            }
        }
        $ctx->stash( 'asset', $asset );
        $ctx->stash( 'asset_thumb', $asset_thumb );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>