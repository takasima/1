<?php
function smarty_function_mtextfieldthumbnailheight ( $args, &$ctx ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $imagemeta = $extfield->extfields_thumb_metadata;
        if ( $imagemeta ) {
            $imagemeta = explode( ',', $imagemeta );
            if ( count( $imagemeta ) > 0) {
                return $imagemeta[1];
            }
        } else {
            if ($asset_thumb = $ctx->stash('asset_thumb')) {
                return $asset_thumb->asset_image_height ? $asset_thumb->asset_image_height : '';
            }
        }
    }
    return '';
}
?>