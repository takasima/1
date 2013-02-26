<?php
function smarty_function_mtcampaignconversioncounter ( $args, &$ctx ) {
    $localvars = array( 'campaign' );
    $campaign_id = $_GET[ 'campaign_id' ];
    if (! isset ( $campaign_id ) ) {
        $campaign_id = $_POST[ 'campaign_id' ];
    }
    $campaign_id = intval( $campaign_id );
    if (! $campaign_id ) {
        return '';
    }
    require_once 'class.mt_campaign.php';
    $where = "campaign_id={$campaign_id}";
    $extra[ 'limit' ] = 1;
    $_campaign = new Campaign;
    $campaign = $_campaign->Find( $where, false, false, false );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $campaign = $campaign[0];
        $campaign_id = $campaign->id;
        $blog_id = $ctx->stash( 'blog_id' );
        $config = $ctx->mt->db()->fetch_plugin_data( 'campaign', "configuration:blog:$blog_id" );
        $conversion_redirect = $config[ 'conversion_redirect' ];
        if (! isset ( $conversion_redirect ) ) {
            require_once( "MTUtil.php" );
            $static_path = static_path( '' );
            $conversion_redirect = $static_path . 'images' . DIRECTORY_SEPARATOR . 'spacer.gif';
        }
        $exclude_ip_table = $config[ 'exclude_ip_table' ];
        $exclude_ip_table = preg_replace( '/\r\n/', '\n', $exclude_ip_table );
        $exclude_ip_table = preg_replace( '/\r/', '\n', $exclude_ip_table );
        $ip_table = preg_split( '/\n/', $exclude_ip_table );
        require_once( "function.mtcampaigncounter.php" );
        if ( check_ip( $_SERVER[ 'REMOTE_ADDR' ], $ip_table ) ) {
            header( "HTTP/1.1 302 Found" );
            header( "Location: " . $conversion_redirect );
            exit();
        }
        $cookie_expire = $config[ 'cookie_expire' ];
        if ( $cookie_expire == '' ) {
            $cookie_expire = 30;
        }
        $timeout = time() + $cookie_expire * 86400;
        $conversion;
        if ( $timeout ) {
            if ( isset( $_COOKIE[ 'mt_campaign_c' ] ) ) {
                $cookie = $_COOKIE[ 'mt_campaign_c' ];
                $cookie_id = preg_split ( '/\-/', $cookie );
                if ( preg_grep( "/^$campaign_id$/", $cookie_id ) ) {
                    $conversion = 1;
                }
            }
        }
        $powercms_files = $ctx->mt->config( 'PowerCMSFilesDir' );
        if (! isset( $powercms_files ) ) {
            $path = $ctx->mt->config( 'MTDir' );
            if ( substr( $path, strlen( $path ) - 1, 1 ) == '/' ) {
                $path = substr( $path, 1, strlen( $path ) -1 );
            }
            $powercms_files = $path . DIRECTORY_SEPARATOR . 'powercms_files' . DIRECTORY_SEPARATOR . 'campaign';
        }
        $filename   = $powercms_files . DIRECTORY_SEPARATOR . 'conversion_' . $campaign->id . '.dat';
        $filename_v = $powercms_files . DIRECTORY_SEPARATOR . 'conversion_v_' . $campaign->id . '.dat';
        $count;
        if ( $conversion == 1 ) {
            if (! file_exists( $filename ) ) {
                touch( $filename );
                $fp = fopen( $filename, "r+" );
                flock( $fp, LOCK_EX );
                fseek( $fp, 0 );
                fputs( $fp, 1 );
                flock( $fp, LOCK_UN );
                fclose( $fp );
                $count = 1;
            } else {
                $fp = fopen( $filename, "r+" );
                flock( $fp, LOCK_EX );
                $count = fgets( $fp, 32 );
                $count++;
                fseek( $fp, 0 );
                fputs( $fp, $count );
                flock( $fp, LOCK_UN );
                fclose( $fp );
                //Task : If Count is NULL
            }
            $campaign->conversion = $count;
        }
        $count_v;
        if (! file_exists( $filename_v ) ) {
            touch( $filename_v );
            $fp = fopen( $filename_v, "r+" );
            flock( $fp, LOCK_EX );
            fseek( $fp, 0 );
            fputs( $fp, 1 );
            flock( $fp, LOCK_UN );
            fclose( $fp );
            $count_v = 1;
        } else {
            $fp = fopen( $filename_v, "r+" );
            flock( $fp, LOCK_EX );
            $count_v = fgets( $fp, 32 );
            $count_v++;
            fseek( $fp, 0 );
            fputs( $fp, $count_v );
            flock( $fp, LOCK_UN );
            fclose( $fp );
        }
        $campaign->conversionview = $count_v;
        $campaign->save();
        header( "HTTP/1.1 302 Found" );
        header( "Location: " . $conversion_redirect );
        exit();
    }
}
?>