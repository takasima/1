package Bookmark::Plugin;
use strict;

use PowerCMS::Util qw( is_cms current_user );

sub _hdlr_bookmarks {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    if (! is_cms( $app ) ) {
        return '';
    }
    my $user = current_user( $app );
    return '' unless $user;
    my @bookmarks = _get_bookmark( $user );
    my $builder = $ctx->stash( 'builder' );
    my $tokens = $ctx->stash( 'tokens' );
    my $i = 0;
    my $glue = $args->{ glue };
    my $lastn = $args->{ lastn };
    my $vars = $ctx->{ __stash }{ vars } ||= {};
    my $res = '';
    for my $bookmark ( @bookmarks ) {
        local $vars->{ __first__ } = !$i;
        local $vars->{ __last__ }  = ! defined $bookmarks[ $i + 1 ] && ! $lastn;
        local $vars->{ __last__ }  = 1 if $lastn && $i >= $lastn;
        local $vars->{ __odd__ }   = ( $i % 2 ) == 0;
        local $vars->{ __even__ }  = ( $i % 2 ) == 1;
        local $vars->{ __counter__ } = $i + 1;
        local $vars->{ key } = $bookmark->{ key };
        local $vars->{ order } = $bookmark->{ order };
        local $vars->{ label } = $bookmark->{ label };
        local $vars->{ url } = $bookmark->{ url };
        local $vars->{ icon } = $bookmark->{ icon };
        my $out = $builder->build( $ctx, $tokens, $cond );
        $res .= $out;
        $res .= $glue if $glue && defined $bookmarks[ $i + 1 ];
        $i++;
    }
    return $res;
}

sub _shortcut_dialog {
    my $app = shift;
    my %param;
    my $user = current_user( $app );
    my $key = $app->param( 'key' );
    my $bookmark;
    my $bookmark_icon;
    my $bookmark_label;
    my $bookmark_order;
    my $bookmark_url = $app->param( 'bookmark_url' );
    if ( (! $key ) && $bookmark_url ) {
        require Digest::MD5;
        $key = Digest::MD5::md5_hex( $bookmark_url );
    }
    if ( $key ) {
        $bookmark = _get_bookmark( $user, $key );
        if ( $bookmark ) {
            $bookmark_url = $bookmark->{ url };
            $bookmark_icon = $bookmark->{ icon };
            $bookmark_label = $bookmark->{ label };
            $bookmark_order = $bookmark->{ order };
            $param{ bookmark_url } = $bookmark_url;
            $param{ bookmark_icon } = $bookmark_icon;
            $param{ bookmark_label } = $bookmark_label;
            $param{ bookmark_order } = $bookmark_order;
        }
    }
    if (! $bookmark ) {
        $param{ bookmark_label } = $app->param( 'bookmark_label' );
        $param{ bookmark_url } = $app->param( 'bookmark_url' );
    }
    my $plugin = MT->component( 'PowerCMS' );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl', 'dialog' );
    $param{ bookmark_old_key } = $key;
    my $tmpl = 'shortcut_dialog.tmpl';
    my $icon_dir = $app->static_file_path;
    if ( $icon_dir =~ /(.*)\/$/ ) {
        $icon_dir = $1;
    }
    $icon_dir = File::Spec->catdir( $icon_dir, 'addons', 'PowerCMS.pack', 'images', 'function_icon_set' );
    my @icon_loop;
    if (-d $icon_dir ) {
        opendir( DIR, $icon_dir );
        my $i = 1;
        while ( defined ( my $file = readdir( DIR ) ) ) {
            if ( $file =~ /(.*)\.png$/ ) {
                push @icon_loop, {
                    name => $file,
                    kind => $1,
                    num  => $i,
                };
                $i++;
            }
        }
        closedir( DIR );
    }
    $param{ icon_loop } = \@icon_loop;
    my $max = _get_bookmark_max_order( $user );
    my $min = _get_bookmark_max_order( $user, 1 );
    if (! $min ) {
        $param{ order_min } = 1;
    } else {
        $param{ order_min } = $min - 0;
    }
    if (! $max ) {
        $param{ order_max } = 1;
    } else {
        $param{ order_max } = $max + 1;
    }
    return $app->build_page( $tmpl, \%param );
}

sub _remove_my_shortcut {
    my $app = shift;
    $app->validate_magic
        or return $app->trans_error( 'Permission denied.' );
    my $user = current_user( $app );
    my $bookmarks = _get_bookmark( $user );
    my $key = $app->param( 'key' );
    my $new_bookmarks;
    if ( $bookmarks ) {
        for my $bk ( keys %$bookmarks ) {
            if ( $bk ne $key ) {
                $new_bookmarks->{ $bk } = $bookmarks->{ $bk };
            }
        }
    }
    $user->bookmarks( $new_bookmarks );
    $user->save or $user->errstr;
    return '';
}

sub _add2shortcut {
    my $app = shift;
    $app->validate_magic
        or return $app->trans_error( 'Permission denied.' );
    my $user = current_user( $app );
    my $bookmark = _get_bookmark( $user );
    my $plugin = MT->component( 'PowerCMS' );
    my $bookmark_url = $app->param( 'bookmark_url' );
    my $bookmark_icon = $app->param( 'bookmark_icon' );
    my $bookmark_label = $app->param( 'bookmark_label' );
    require TrimJ::Tags;
    $bookmark_label = TrimJ::Tags::_filter_trimj_to( $bookmark_label, [ 13, '...' ] );
    my $bookmark_order = $app->param( 'bookmark_order' );
    $bookmark_order = 1 if (! $bookmark_order );
    require Digest::MD5;
    my $key = Digest::MD5::md5_hex( $bookmark_url );
    my $bookmark_old_key = $app->param( 'bookmark_old_key' );
    if ( $bookmark_old_key eq $key ) {
        $bookmark_old_key = '';
    }
    my $bookmarks;
    $bookmarks->{ url } = $bookmark_url;
    $bookmarks->{ label } = $bookmark_label;
    $bookmarks->{ order } = $bookmark_order;
    $bookmarks->{ icon } = $bookmark_icon;
    my @orders;
    push ( @orders, $bookmark_order );
    my $new_bookmarks;
    if ( $bookmark ) {
        for my $bk_key ( keys %$bookmark ) {
            my $current = $bookmark->{ $bk_key };
            my $ord = $current->{ order };
            if ( $bk_key eq $bookmark_old_key ) {
            } elsif ( $bk_key eq $key ) {
            } else {
                if ( grep { $_ =~ /^$ord$/ } @orders ) {
                    $ord++;
                    $current->{ order } = $ord;
                    push ( @orders, $ord );
                }
            }
            $new_bookmarks->{ $bk_key } = $current;
        }
    }
    $new_bookmarks->{ $key } = $bookmarks;
    $user->bookmarks( $new_bookmarks );
    $user->save or $user->errstr;
    $app->add_return_arg( save_changes => 1 );
    $app->call_return;
}

sub _get_bookmark_max_order {
    my ( $user, $want_min ) = @_;
    my $bookmark = $user->bookmarks;
    if ( $bookmark ) {
        my $max = 0;
        my $min = 1000;
        for my $key ( keys %$bookmark ) {
            my $order = $bookmark->{ $key }->{ order };
            if ( $max < $order ) {
                $max = $order;
            }
            if ( $min > $order ) {
                $min = $order;
            }
        }
        if ( $want_min ) {
            return $min;
        } else {
            return $max;
        }
    } else {
        return 0;
    }
}

sub _get_bookmark {
    my ( $user, $key ) = @_;
    my $bookmark = $user->bookmarks;
    if ( $bookmark ) {
        if ( $key ) {
            return $bookmark->{ $key };
        } else {
            if (! wantarray ) {
                return $bookmark;
            }
            my @bookmark_array;
            my $bookmarks;
            my %bks;
            for my $key ( keys %$bookmark ) {
                my $order = $bookmark->{ $key }->{ order };
                $bks{ $order } = $key;
            }
            for my $num ( sort { $a <=> $b } keys %bks ){
                $bookmark->{ $bks{ $num } }->{ key } = $bks{ $num };
                push ( @bookmark_array, $bookmark->{ $bks{ $num } } );
                $bookmarks->{ $bks{ $num } } = $bookmark->{ $bks{ $num } };
            }
            if ( wantarray ) {
                return @bookmark_array;
            } else {
                return $bookmarks;
            }
        }
    } else {
        return;
    }
}

1;