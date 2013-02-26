<?php
function smarty_function_mtextfieldthumbnail ( $args, $ctx ) {
    require_once ( 'function.mtblogurl.php' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    if ( isset ( $extfield ) ) {
        $blog = $ctx->stash( 'blog' );
        $buf = array(
            'id' => $blog->blog_id
        );
        $blog_url = smarty_function_mtblogurl( $buf, $ctx );
        $blog_url = preg_replace( '/\/$/', '', $blog_url );
        $filepath = $extfield->extfields_thumbnail;
        $filepath = str_replace ( '%r', $blog_url, $filepath );
        return $filepath;
    }
    return '';
}
?>