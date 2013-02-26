<?php
function smarty_function_mtextfieldthumbnailwidth ( $args, &$ctx ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $imagemeta = $extfield->extfields_thumb_metadata;
        if ( $imagemeta ) {
            $imagemeta = explode( ',', $imagemeta );
            if ( count( $imagemeta ) > 0 ) {
                return $imagemeta[0];
            }
        } else {
            if ( $asset_thumb = $ctx->stash( 'asset_thumb' ) ) {
                return $asset_thumb->asset_image_width ? $asset_thumb->asset_image_width : '';
            }
        }
    }
    return '';
}
?>