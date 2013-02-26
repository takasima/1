<?php
function smarty_function_mtcampaignredirect ( $args, &$ctx ) {
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
    if ( isset( $campaign ) ) {
        $campaign = $campaign[0];
        $url = $campaign->url;
        $blog_id = $ctx->stash( 'blog_id' );
        $config  = $ctx->mt->db()->fetch_plugin_data( 'campaign', "configuration:blog:$blog_id" );
        $exclude_ip_table = $config[ 'exclude_ip_table' ];
        $exclude_ip_table = preg_replace( '/\r\n/', '\n', $exclude_ip_table );
        $exclude_ip_table = preg_replace( '/\r/', '\n', $exclude_ip_table );
        $ip_table = preg_split( '/\n/', $exclude_ip_table );
        require_once( "function.mtcampaigncounter.php" );
        if ( check_ip( $_SERVER[ 'REMOTE_ADDR' ], $ip_table ) ) {
            if ( $url ) {
                header( "HTTP/1.1 302 Found" );
                header( "Location: " . $url );
                exit();
            } else {
                return 0;
            }
        }
        $cookie_expire = $config[ 'cookie_expire' ];
        if ( $cookie_expire == '' ) {
            $cookie_expire = 30;
        }
        $timeout = time() + $cookie_expire * 86400;
        $uniq;
        if ( $timeout ) {
            if (! isset( $_COOKIE[ 'mt_campaign_c' ] ) ) {
                setcookie( 'mt_campaign_c', $campaign_id . '-' , $timeout );
                $uniq = 1;
            } else {
                $cookie = $_COOKIE[ 'mt_campaign_c' ];
                $cookie_id = preg_split ( '/\-/', $cookie );
                if ( preg_grep( "/^$campaign_id$/", $cookie_id ) ) {
                    setcookie( 'mt_campaign_c', $cookie, $timeout );
                } else {
                    setcookie( 'mt_campaign_c', $campaign_id . '-' . $cookie , $timeout );
                    //Task : When cookie is too large.
                    $uniq = 1;
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
        $filename   = $powercms_files . DIRECTORY_SEPARATOR . 'clickcount_' . $campaign->id . '.dat';
        $filename_u = $powercms_files . DIRECTORY_SEPARATOR . 'clickcount_uniq_' . $campaign->id . '.dat';
        $count;
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
        $count_u;
        if ( $uniq == 1 ) {
            if (! file_exists( $filename_u ) ) {
                touch( $filename_u );
                $fp = fopen( $filename_u, "r+" );
                flock( $fp, LOCK_EX );
                fseek( $fp, 0 );
                fputs( $fp, 1 );
                flock( $fp, LOCK_UN );
                fclose( $fp );
                $count_u = 1;
            } else {
                $fp = fopen( $filename_u, "r+" );
                flock( $fp, LOCK_EX );
                $count_u = fgets( $fp, 32 );
                $count_u++;
                fseek( $fp, 0 );
                fputs( $fp, $count_u );
                flock( $fp, LOCK_UN );
                fclose( $fp );
                //Task : If Count is NULL
            }
            $campaign->uniqclicks = $count_u;
        }
        $campaign->clicks = $count;
        if ( $campaign->max_clicks ) {
            if ( $campaign->max_clicks <= $count ) {
                $campaign->status = 4;
            }
        }
        if ( $campaign->max_uniqclicks ) {
            if ( $campaign->max_uniqclicks <= $campaign->uniqclicks ) {
                $campaign->status = 4;
            }
        }
        $campaign->save();
        if ( $url ) {
            header( "HTTP/1.1 302 Found" );
            header( "Location: " . $url );
            exit();
        }
    }
    return '';
}
?>