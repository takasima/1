<?php
function smarty_function_mtextfieldfilesize ( $args, &$ctx ) {
    require_once ( 'function.mtblogsitepath.php' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    $unit     = $args[ 'unit' ];
    $decimals = $args[ 'decimals' ];
    if ( isset ( $extfield ) ) {
        $path = $extfield->extfields_text;
        $blog = $ctx->stash( 'blog' );
        $buf = array(
            'id' => $blog->blog_id
        );
        $blog_path = smarty_function_mtblogsitepath( $buf, $ctx );
        $blog_path = preg_replace( '/\/$/', '', $blog_path );
        $path = str_replace ( '%r', $blog_path, $path );
        if ( file_exists( $path ) ) {
            $size = filesize( $path );
        } else {
            return '';
        }
        $units = Array( 'b', 'kb', 'mb', 'gb', 'tb', 'pb', 'eb' );
        $ext = $units[0];
        for ( $i=1; ( ( $i < count( $units ) ) && ( $size >= 1024 ) ); $i++ ) {
            $ext = $units[ $i ];
            $size = $size / 1024;
            if ( $unit == $ext ) {
                return round( $size, $decimals );
            }
        }
    }
    return '';
}
?>