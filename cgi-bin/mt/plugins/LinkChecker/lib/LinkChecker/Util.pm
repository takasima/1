package LinkChecker::Util;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can is_windows );

sub separater {
    return is_windows() ? ( '\\', '\\\\' ) : ( '/', '/' );
}

sub can_link_check {
    my ( $blog, $user ) = @_;
    return is_user_can( $blog, $user, 'rebuild' );
}

sub check_plugin_settings {
    my $plugin = MT->component( 'LinkChecker' );
    if ( $plugin->get_config_value( 'innerlink' ) || $plugin->get_config_value( 'outlink' ) ) {
        return 1;
    }
    return 0;
}

sub check_exclude {
    my $path = shift;
    my $plugin = MT->component( 'LinkChecker' );
    my $exclude_suffix = $plugin->get_config_value( 'lc_exclude_suffix' );
    return 1 unless $exclude_suffix;
    my @suffixes = split( /,/, $exclude_suffix );
    for my $suffix ( @suffixes ) {
        $suffix = quotemeta( $suffix );
        if ( $path =~ /$suffix$/ ) {
            return 0;
        }
    }
    return 1;
}

sub backslash2slash {
    my $str = shift;
    $str =~ s/\\/\//g;
    return $str;
}

sub slash2backslash {
    my $str = shift;
    $str =~ s/\//\\/g;
    return $str;
}

sub quotebackslash {
    my $str = shift;
    $str =~ s/\\/\\\\/g;
    return $str;
}

1;
