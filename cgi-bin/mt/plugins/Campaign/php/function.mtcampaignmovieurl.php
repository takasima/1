<?php
function smarty_function_mtcampaignmovieurl ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $blog = $ctx->stash( 'blog' );
        $asset_id = $campaign->movie_id;
        $movie = $ctx->mt->db()->fetch_assets( array( 'id' => $asset_id ) );
        if (! isset( $movie ) ) {
            return '';
        }
        if ( count( $movie ) == 1 ) {
            $movie = $movie[0];
        }
        $url = $movie->url;
        $site_url = $blog->site_url();
        $url = preg_replace( '/^%r/', $site_url, $url );
        return $url;
    }
}
?>