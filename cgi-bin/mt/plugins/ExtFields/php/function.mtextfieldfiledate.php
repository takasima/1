<?php
function smarty_function_mtextfieldfiledate ( $args, &$ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    require_once( 'function.mtblogsitepath.php' );
    require_once ( 'extfield.util.php' );
    $extfield = get_extfield( $args, $ctx );
    $format = $args[ 'format' ];
    if ( isset ( $extfield ) ) {
        $blog = $ctx->stash( 'blog' );
        $buf = array(
            'id' => $blog->blog_id
        );
        $blog_path = smarty_function_mtblogsitepath( $buf, $ctx );
        $blog_path = $app->chomp_dir( $blog_path );
        $filepath = $extfield->extfields_text;
        $filepath = str_replace ( '%r', $blog_path, $filepath );
        if ( DIRECTORY_SEPARATOR != '/' ) {
            $filepath = str_replace( '/', DIRECTORY_SEPARATOR, $filepath );
        }
        if ( file_exists( $filepath ) ) {
            require_once( "MTUtil.php" );
            $ts = date( 'YmdHis', filemtime( $filepath ) );
            $ts = format_ts( $format, $ts, $blog, isset( $args[ 'language' ] ) ? $args[ 'language' ] : NULL );
            return $ts;
        }
        return $filepath;
    }
    return '';
}
?>