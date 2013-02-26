package Pager::Util;
use strict;
use base qw( Exporter );

our @EXPORT_OK = qw( ceil site_path chomp_dir is_windows );

sub ceil {
    my $var = shift;
    my $a = 0;
    $a = 1 if ( $var > 0 and $var != int ( $var ) );
    return int ( $var + $a );
}

sub site_path {
    my ( $blog, $exclude_archive_path ) = @_;
    my $site_path;
    unless ( $exclude_archive_path ) {
        $site_path = $blog->archive_path;
    }
    $site_path ||= $blog->site_path;
    return chomp_dir( $site_path );
}

sub chomp_dir {
    my $dir = shift;
    require File::Spec;
    my @path = File::Spec->splitdir( $dir );
    $dir = File::Spec->catdir( @path );
    return $dir;
}

sub is_windows { $^O eq 'MSWin32' ? 1 : 0 }

1;
