<?php
function smarty_function_mtaltsearchquery ( $args, $ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $query = $app->param( 'query' );
    $from = mb_detect_encoding( $query,'UTF-8,EUC-JP,SJIS,JIS' );
    $charset = $ctx->mt->config( 'PublishCharset' );
    $charset or $charset = 'UTF-8';
    $query = mb_convert_encoding( $query, $charset, $from );
    $query = preg_replace( '/\s{2,}/', ' ', $query );
    $query = preg_replace( '/^\s/', '', $query );
    $query = preg_replace( '/\s$/', '', $query );
    if (! $args[ 'pass' ] ) {
        $query = htmlspecialchars( $query, ENT_QUOTES );
    }
    $query = str_replace( '\\', '', $query );
    return $query;
}
?>