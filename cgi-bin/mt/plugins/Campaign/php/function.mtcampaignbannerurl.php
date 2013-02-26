<?php
function smarty_function_mtcampaignbannerurl ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $image = get_campaign_image( $args, $ctx, $campaign );
        return $image[0];
    }
}
function mtcampaignbannerurl_error() {}
function get_campaign_image( $args, $ctx, $campaign ) {
    require_once( "MTUtil.php" );
    if ( $ctx->stash( 'blog_id' ) != $campaign->blog_id ) {
        $blog_id = $campaign->blog_id;
        $blog = $ctx->mt->db()->fetch_blog( $blog_id );
    } else {
        $blog_id = $ctx->stash( 'blog_id' );
        $blog = $ctx->stash( 'blog' );
    }
    $config = $ctx->mt->db()->fetch_plugin_data( 'campaign', "configuration:blog:$blog_id" );
    $max_banner_size = $config[ 'max_banner_size' ];
    $banner_width = $campaign->banner_width;
    $banner_height = $campaign->banner_height;
    $asset_id = $campaign->image_id;
    if (! isset( $asset_id ) ) {
        return '';
    }
    $image = $ctx->mt->db()->fetch_assets( array( 'id' => $asset_id ) );
    if (! isset( $image ) ) {
        return '';
    }
    if ( count( $image ) == 1 ) {
        $image = $image[0];
    }
    $path = asset_path( $image->file_path, $blog );
    $url = $image->url;
    $site_url = $blog->site_url();
    $site_url = preg_replace( '/\/$/', '', $site_url );
    $url = preg_replace( '/^%r/', $site_url, $url );
    if (! file_exists( $path ) ) {
        return '';
    }
    $mtime = filemtime( $path );
    $params;
    if ( ( $banner_width && $banner_height ) &&
        ( ( $image->image_width != $banner_width ) ||
        ( $image->image_height != $banner_height ) ) ) {
        $params[ 'width' ]  = $banner_width;
        $params[ 'height' ] = $banner_height;
    } else if ( $banner_width && ( $image->image_width != $banner_width ) ) {
        $params[ 'width' ]  = $banner_width;
    } else if ( $banner_height && ( $image->image_height != $banner_height ) ) {
        $params[ 'height' ] = $banner_height;
    } else {
        if ( ( $image->image_width > $max_banner_size ) ||
            ( $image->image_height > $max_banner_size ) ) {
            if ( $image->image_height < $image->image_width ) {
                $params[ 'width' ] = $max_banner_size;
            } else {
                $params[ 'height' ] = $max_banner_size;
            }
        } else {
            return array( $url, $image->image_width, $image->image_height, $path );
        }
//         set_error_handler('mtcampaignbannerurl_error');
//         $thumbnail = get_thumbnail_file( $image, $blog, $params );
//         $file = $thumbnail[3];
//         if ( file_exists( $file ) ) {
//             $t_time = filemtime( $file );
//             if ( $mtime > $t_time ) {
//                 unlink ( $file );
//                 $thumbnail = get_thumbnail_file( $image, $blog, $params );
//             }
//         }
//         return $thumbnail;
    }
    set_error_handler( 'mtcampaignbannerurl_error' );
    $thumbnail = get_thumbnail_file( $image, $blog, $params );
    $file = $thumbnail[3];
    if ( file_exists( $file ) ) {
        $t_time = filemtime( $file );
        if ( $mtime > $t_time ) {
            unlink ( $file );
            $thumbnail = get_thumbnail_file( $image, $blog, $params );
        }
    }
    return $thumbnail;
}
