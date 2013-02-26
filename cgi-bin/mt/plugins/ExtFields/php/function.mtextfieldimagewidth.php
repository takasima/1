<?php
function smarty_function_mtextfieldimagewidth ( $args, &$ctx ) {
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $imagemeta = $extfield->extfields_metadata;
        if ( $imagemeta ) {
            $imagemeta = explode( ',', $imagemeta );
            if ( count( $imagemeta ) > 0 ) {
                return $imagemeta[0];
            }
        } else {
            if ( $asset = $ctx->stash( 'asset' ) ) {
                return $asset->asset_image_width ? $asset->asset_image_width : '';
            }
        }
    }
    return '';
}
?>