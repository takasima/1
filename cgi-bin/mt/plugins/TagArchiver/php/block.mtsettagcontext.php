<?php
function smarty_block_mtsettagcontext ( $args, $content, &$ctx, &$repeat ) {
    $tag = $ctx->stash( 'tag' );
    if (! $tag ) {
        if (! isset( $content ) ) {
            $mt = $ctx->mt;
            $path = NULL;
            if ( !$path && $_SERVER[ 'REQUEST_URI' ] ) {
                $path = $_SERVER[ 'REQUEST_URI' ];
                // strip off any query string...
                $path = preg_replace( '/\?.*/', '', $path );
                // strip any duplicated slashes...
                $path = preg_replace( '!/+!', '/', $path );
            }
            if ( preg_match( '/IIS/', $_SERVER[ 'SERVER_SOFTWARE' ] ) ) {
                if ( preg_match( '/^\d+;( .* )$/', $_SERVER[ 'QUERY_STRING' ], $matches ) ) {
                    $path = $matches[1];
                    $path = preg_replace( '!^http://[^/]+!', '', $path );
                    if ( preg_match( '/\?( .+ )?/', $path, $matches ) ) {
                        $_SERVER[ 'QUERY_STRING' ] = $matches[1];
                        $path = preg_replace( '/\?.*$/', '', $path );
                    }
                }
            }
            $path = preg_replace( '/\\\\/', '\\\\\\\\', $path );
            $pathinfo = pathinfo( $path );
            $ctx->stash( '_basename', $pathinfo[ 'filename' ] );
            if ( isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] ) ) {
                $_SERVER[ 'QUERY_STRING' ] = getenv( 'REDIRECT_QUERY_STRING' );
            }
            if ( preg_match( '/\.( \w+ )$/', $path, $matches ) ) {
                $req_ext = strtolower( $matches[1] );
            }
            $data = $mt->resolve_url( $path );
            $tag = $data->fileinfo_tag_id;
            $archive_tag = $mt->db()->fetch_tag( $tag );
            if ( $archive_tag ) {
                $ctx->stash( 'tag', $archive_tag );
                $ctx->stash( 'Tag', $archive_tag );
                $vars =& $ctx->__stash[ 'vars' ];
                $vars[ 'tag_name' ] = $archive_tag->name;
            }
        }
    }
    return $content;
}
?>