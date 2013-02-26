<?php
function smarty_function_mtcampaigncounter ( $args, &$ctx ) {
    $campaign = $ctx->stash( 'campaign' );
    if (! isset( $campaign ) ) {
        return $ctx->error();
    } else {
        $campaign_id = $campaign->id;
        $blog_id = $ctx->stash( 'blog_id' );
        $config = $ctx->mt->db()->fetch_plugin_data( 'campaign', "configuration:blog:$blog_id" );
        $exclude_ip_table = $config[ 'exclude_ip_table' ];
        $exclude_ip_table = preg_replace( '/\r\n/', '\n', $exclude_ip_table );
        $exclude_ip_table = preg_replace( '/\r/', '\n', $exclude_ip_table );
        $ip_table = preg_split( '/\n/', $exclude_ip_table );
        if ( check_ip( $_SERVER[ 'REMOTE_ADDR' ], $ip_table ) ) {
            return $campaign->displays;
        }
        $cookie_expire = $config[ 'cookie_expire' ];
        if ( $cookie_expire == '' ) {
            $cookie_expire = 30;
        }
        $timeout = time() + $cookie_expire * 86400;
        $uniq;
        if ( $timeout ) {
            if (! isset( $_COOKIE[ 'mt_campaign_p' ] ) ) {
                setcookie( 'mt_campaign_p', $campaign_id . '-' , $timeout );
                $uniq = 1;
            } else {
                $cookie = $_COOKIE[ 'mt_campaign_p' ];
                $cookie_id = preg_split ( '/\-/', $cookie );
                if ( preg_grep( "/^$campaign_id$/", $cookie_id ) ) {
                    setcookie( 'mt_campaign_p', $cookie, $timeout );
                } else {
                    setcookie( 'mt_campaign_p', $campaign_id . '-' . $cookie , $timeout );
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
        $filename   = $powercms_files . DIRECTORY_SEPARATOR . 'counter_' . $campaign->id . '.dat';
        $filename_u = $powercms_files . DIRECTORY_SEPARATOR . 'counter_uniq_' . $campaign->id . '.dat';
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
        }
        if ( $uniq == 1 ) {
            $count_u;
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
            $campaign->uniqdisplays = $count_u;
        }
        $campaign->displays = $count;
        if ( $campaign->max_displays ) {
            if ( $campaign->max_displays <= $count ) {
                $campaign->status = 4;
            }
        }
        $campaign->save();
        return $campaign->displays;
    }
}
function check_ip ( $remote_ip, $table ) {
    if ( preg_grep( "/^$remote_ip$/", $table ) ) {
        return 1;
    }
    $ip_table = join ( "\n", $table );
    if ( preg_match( '/(^[0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}\.)([0-9]{1,}$)/', $remote_ip, $matches ) ) {
        $bits = array( 0, 126, 62, 30, 14, 6, 2 );
        $check = $matches[1];
        $last = $matches[2];
        if ( preg_match( "/$check([0-9]{1,})\/([0-9]{1,})/", $ip_table, $matches ) ) {
            $begin = $matches[1];
            $bit = $matches[2];
            if ( ( $begin == '0' ) && ( $bit == '24' ) ) {
                if ( ( 0 < $last ) && ( 255 > $last ) ) {
                    return 1;
                }
            } else {
                $bit = $bit - 24;
                $range = $bits[ $bit ];
                $end = $begin + $range;
                if ( ( $last >= $begin ) && ( $last <= $end ) ) {
                    return 1;
                }
            }
        }
    }
    return 0;
}
?>