package MT::App::CMS::Campaign;

use strict;
use base qw( MT::App );
use MT;
use File::Spec;
use Fcntl qw( :DEFAULT :flock );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( format_LF valid_ip write2file );

@MT::App::CMS::Campaign = qw( MT::App );

sub init_request {
    my $app = shift;
    $app->SUPER::init_request( @_ );
    $app->{ default_mode } = 'counter';
    $app->add_methods( counter => \&_counter );
    $app->add_methods( redirect => \&_redirect );
    $app->add_methods( conversion => \&_conversion );
    $app;
}

sub _counter {
    my $app = shift;
    my $plugin = MT->component( 'Campaign' );
    my $campaign_id = $app->param( 'campaign_id' );
    if ( $campaign_id ) {
        my $campaign = $app->model( 'campaign' )->load( $campaign_id );
        if ( $campaign ) {
            require Campaign::Tools;
            my $campaign_dir = Campaign::Tools::_make_campaign_dir();
            if ( $campaign_dir ) {
                my $exclude_ip_table = $plugin->get_config_value( 'exclude_ip_table', 'blog:'. $campaign->blog_id );
                $exclude_ip_table = format_LF( $exclude_ip_table );
                my @ip_table = split( /\n/, $exclude_ip_table );
                if ( valid_ip( $app->remote_ip, \@ip_table ) ) {
                    return $campaign->displays;
                }
                my $file = File::Spec->catfile( $campaign_dir, 'counter_' . $campaign->id . '.dat' );
                if (! -f $file ) {
                    write2file( $file, '0' );
                }
                if ( -f $file ) {
                    open my $fh, "+<", $file or die "$!:$file";
                    flock $fh, LOCK_EX;
                    my $count = <$fh>;
                    $count++;
                    seek $fh, 0, 0;
                    print $fh $count;
                    close $fh;
                    $campaign->displays( $count );
                    if ( $campaign->max_displays ) {
                        if ( $campaign->max_displays <= $count ) {
                            $campaign->status( 4 );
                        }
                    }
                    # $campaign->save or die $campaign->errstr;
                }
                my $cookie = $app->cookie_val( 'mt_campaign_p' ) || '';
                my $cookie_expire = $plugin->get_config_value( 'cookie_expire', 'blog:'. $campaign->blog_id );
                my $timeout = time + $cookie_expire * 86400;
                my $uniq;
                if (! $cookie ) {
                    $uniq = 1;
                    my %new_cookie = ( -name    => 'mt_campaign_p',
                                       -value   => $campaign_id . '-',
                                       -expires => $timeout
                                       );
                    $app->bake_cookie( %new_cookie );
                } else {
                    my @cookie_id = split( /\-/, $cookie );
                    if ( grep( /^$campaign_id$/, @cookie_id ) ) {
                        $uniq = 0;
                        my %new_cookie = ( -name    => 'mt_campaign_p',
                                           -value   => $cookie,
                                           -expires => $timeout
                                           );
                        $app->bake_cookie( %new_cookie );
                    } else {
                        $uniq = 1;
                        my %new_cookie = ( -name    => 'mt_campaign_p',
                                           -value   => $campaign_id . '-' . $cookie,
                                           -expires => $timeout
                                           );
                        $app->bake_cookie( %new_cookie );
                    }
                }
                if ( $uniq ) {
                    my $file = File::Spec->catfile( $campaign_dir, 'counter_uniq_' . $campaign->id . '.dat' );
                    if (! -f $file ) {
                        write2file( $file, '0' );
                    }
                    if ( -f $file ) {
                        open my $fh, "+<", $file or die "$!:$file";
                        flock $fh, LOCK_EX;
                        my $count = <$fh>;
                        $count++;
                        seek $fh, 0, 0;
                        print $fh $count;
                        close $fh;
                        $campaign->uniqdisplays( $count );
                        if ( $campaign->max_uniqdisplays ) {
                            if ( $campaign->max_uniqdisplays <= $count ) {
                                $campaign->status( 4 );
                            }
                        }
                    }
                }
                $campaign->save or die $campaign->errstr;
            }
            return $campaign->displays;
        }
    }
}

sub _redirect {
    my $app = shift;
    my $plugin = MT->component( 'Campaign' );
    my $campaign_id = $app->param( 'campaign_id' );
    if ( $campaign_id ) {
        my $campaign = $app->model( 'campaign' )->load( $campaign_id );
        if ( $campaign ) {
            require Campaign::Tools;
            my $campaign_dir = Campaign::Tools::_make_campaign_dir();
            if ( $campaign_dir ) {
                my $exclude_ip_table = $plugin->get_config_value( 'exclude_ip_table', 'blog:'. $campaign->blog_id );
                $exclude_ip_table = format_LF( $exclude_ip_table );
                my @ip_table = split( /\n/, $exclude_ip_table );
                if ( valid_ip( $app->remote_ip, \@ip_table ) ) {
                    if ( $campaign->url ) {
                        $app->redirect( $campaign->url );
                    }
                    return '';
                }
                my $file = File::Spec->catfile( $campaign_dir, 'clickcount_' . $campaign->id . '.dat' );
                if (! -f $file ) {
                    write2file( $file, '0' );
                }
                if ( -f $file ) {
                    open my $fh, "+<", $file or die "$!:$file";
                    flock $fh, LOCK_EX;
                    my $count = <$fh>;
                    $count++;
                    seek $fh, 0, 0;
                    print $fh $count;
                    close $fh;
                    $campaign->clicks( $count );
                    if ( $campaign->max_clicks ) {
                        if ( $campaign->max_clicks <= $count ) {
                            $campaign->status( 4 );
                        }
                    }
                    # $campaign->save or die $campaign->errstr;
                }
                my $cookie = $app->cookie_val( 'mt_campaign_c' ) || '';
                my $cookie_expire = $plugin->get_config_value( 'cookie_expire', 'blog:'. $campaign->blog_id );
                my $timeout = time + $cookie_expire * 86400;
                my $uniq;
                if (! $cookie ) {
                    $uniq = 1;
                    my %new_cookie = ( -name    => 'mt_campaign_c',
                                       -value   => $campaign_id . '-',
                                       -expires => $timeout
                                       );
                    $app->bake_cookie( %new_cookie );
                } else {
                    my @cookie_id = split( /\-/, $cookie );
                    if ( grep( /^$campaign_id$/, @cookie_id ) ) {
                        $uniq = 0;
                        my %new_cookie = ( -name    => 'mt_campaign_c',
                                           -value   => $cookie,
                                           -expires => $timeout
                                           );
                        $app->bake_cookie( %new_cookie );
                    } else {
                        $uniq = 1;
                        my %new_cookie = ( -name    => 'mt_campaign_c',
                                           -value   => $campaign_id . '-' . $cookie,
                                           -expires => $timeout
                                           );
                        $app->bake_cookie( %new_cookie );
                    }
                }
                if ( $uniq ) {
                    my $file = File::Spec->catfile( $campaign_dir, 'clickcount_uniq_' . $campaign->id . '.dat' );
                    if (! -f $file ) {
                        write2file( $file, '0' );
                    }
                    if ( -f $file ) {
                        open my $fh, "+<", $file or die "$!:$file";
                        flock $fh, LOCK_EX;
                        my $count = <$fh>;
                        $count++;
                        seek $fh, 0, 0;
                        print $fh $count;
                        close $fh;
                        $campaign->uniqclicks( $count );
                        if ( $campaign->max_uniqclicks ) {
                            if ( $campaign->max_uniqclicks <= $count ) {
                                $campaign->status( 4 );
                            }
                        }
                    }
                }
                $campaign->save or die $campaign->errstr;
            }
            if ( $campaign->url ) {
                $app->redirect( $campaign->url );
            }
        }
    }
}

sub _conversion {
    my $app = shift;
    my $plugin = MT->component( 'Campaign' );
    my $campaign_id = $app->param( 'campaign_id' );
    if ( $campaign_id ) {
        my $campaign = $app->model( 'campaign' )->load( $campaign_id );
        my $conversion_redirect = $plugin->get_config_value( 'conversion_redirect', 'blog:'. $campaign->blog_id );
        if (! $conversion_redirect ) {
            $conversion_redirect = $app->base . $app->static_path . 'images/spacer.gif';
        }
        if ( $campaign ) {
            require Campaign::Tools;
            my $campaign_dir = Campaign::Tools::_make_campaign_dir();
            if ( $campaign_dir ) {
                my $exclude_ip_table = $plugin->get_config_value( 'exclude_ip_table', 'blog:'. $campaign->blog_id );
                $exclude_ip_table = format_LF( $exclude_ip_table );
                my @ip_table = split( /\n/, $exclude_ip_table );
                if ( valid_ip( $app->remote_ip, \@ip_table ) ) {
                    $app->redirect( $conversion_redirect );
                    return '';
                }
                my $file = File::Spec->catfile( $campaign_dir, 'conversion_v_' . $campaign->id . '.dat' );
                if (! -f $file ) {
                    write2file( $file, '0' );
                }
                if ( -f $file ) {
                    open my $fh, "+<", $file or die "$!:$file";
                    flock $fh, LOCK_EX;
                    my $count = <$fh>;
                    $count++;
                    seek $fh, 0, 0;
                    print $fh $count;
                    close $fh;
                    $campaign->conversionview( $count );
                    # $campaign->save or die $campaign->errstr;
                }
                my $cookie = $app->cookie_val( 'mt_campaign_c' ) || '';
                my $cookie_expire = $plugin->get_config_value( 'cookie_expire', 'blog:'. $campaign->blog_id );
                my $timeout = time + $cookie_expire * 86400;
                my $conversion;
                if (! $cookie ) {
                    $conversion = 1;
                } else {
                    my @cookie_id = split( /\-/, $cookie );
                    if ( grep( /^$campaign_id$/, @cookie_id ) ) {
                        $conversion = 0;
                    } else {
                        $conversion = 1;
                    }
                }
                if ( $conversion ) {
                    my $file = File::Spec->catfile( $campaign_dir, 'conversion_' . $campaign->id . '.dat' );
                    if (! -f $file ) {
                        write2file( $file, '0' );
                    }
                    if ( -f $file ) {
                        open my $fh, "+<", $file or die "$!:$file";
                        flock $fh, LOCK_EX;
                        my $count = <$fh>;
                        $count++;
                        seek $fh, 0, 0;
                        print $fh $count;
                        close $fh;
                        $campaign->conversionview( $count );
                    }
                }
                $campaign->save or die $campaign->errstr;
            }
            $app->redirect( $conversion_redirect );
        }
    }
}

1;
