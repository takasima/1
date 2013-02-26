package PowerSearch::Util;
use strict;
use warnings;
use lib qw( addons/PowerCMS.pack/lib );
use base qw( Exporter );

our @EXPORT_OK = qw(
    _get_estcmdpath _get_estcmdindex _get_estfilterpath _get_tempdir
    _timezone _to_hash
);

use English;

use MT;
use PowerCMS::Util qw( error_log );

sub _get_tempdir {
    my $plugin = MT->component('PowerSearch');

    my $temp_dir = MT->config('TempDir') || MT->config('TmpDir');

    if ( !-e $temp_dir ) {
        _error_message(
            $plugin->translate( '[_1] is not exist. Quit.', $temp_dir ),
            "$temp_dir is not exist. Quit.\n" );
        return 0;
    }

    if ( !-w $temp_dir ) {
        _error_message(
            $plugin->translate( '[_1] is not writable. Quit.', $temp_dir ),
            "$temp_dir is not writable. Quit.\n" );
        return 0;
    }

    return $temp_dir;
}

sub _get_estcmdpath {
    my $plugin = MT->component('PowerSearch');

    my $estcmdpath = MT->config('EstcmdPath');

    unless ($estcmdpath) {
        _error_message(
            $plugin->translate( '[_1] is not set. Quit.', "EstcmdPath" ),
            "ExtcmdPath is not set. Quit.\n" );
        return 0;
    }

    unless ( -e $estcmdpath ) {
        _error_message(
            $plugin->translate( '[_1] is not exist. Quit.', "EstcmdPath" ),
            "ExtcmdPath is not exist. Quit.\n" );
        return 0;
    }

    return $estcmdpath;
}

sub _get_estcmdindex {
    my $plugin = MT->component('PowerSearch');

    my $index = MT->config('EstcmdIndex');

    unless ($index) {
        _error_message(
            $plugin->translate( '[_1] is not set. Quit.', "EstcmdIndex" ),
            "EstcmdIndex is not set. Quit.\n" );
        return 0;
    }

    if ( !-d $index ) {
        my $dirname = File::Basename::dirname($index);
        unless ( !-w $dirname ) {
            _error_message(
                $plugin->translate(
                    '[_1] is not writable. Quit.',
                    "EstcmdIndex"
                ),
                "EstcmdIndex is not writable. Quit.\n"
            );
        }
    }
    elsif ( !-w $index ) {
        _error_message(
            $plugin->translate(
                '[_1] is not writable. Quit.', "EstcmdIndex"
            ),
            "EstcmdIndex is not writable. Quit.\n"
        );
        return 0;
    }

    return File::Spec->canonpath($index);
}

sub _get_estfilterpath {
    my $plugin = MT->component('PowerSearch');

    my $estfilterpath = MT->config('EstFilterPath');

    unless ($estfilterpath) {
        _error_message(
            $plugin->translate( '[_1] is not set. Quit.', "EstFilterPath" ),
            "EstFilterPath is not set. Quit.\n" );
        return 0;
    }

    if ( !-d $estfilterpath ) {
        _error_message(
            $plugin->translate( '[_1] is not exist. Quit.', "EstFilterPath" ),
            "EstFilterPath is not exist. Quit.\n"
        );
        return 0;
    }

    return $estfilterpath;
}

sub _timezone {
    my $blog = shift;
    return '' unless $blog;

    my $so                  = $blog->server_offset;
    my $no_colon            = '';
    my $partial_hour_offset = 60 * abs( $so - int($so) );
    sprintf( '%s%02d%s%02d',
        $so < 0   ? '-' : '+', abs($so),
        $no_colon ? ''  : ':', $partial_hour_offset );
}

sub _to_hash {
    my $id = shift;

    if ( Encode::is_utf8($id) ) {
        $id = Encode::encode_utf8($id);
    }
    require Digest::MD5;
    $id = Digest::MD5::md5_hex($id);
}

sub _error_message {
    my $message  = shift;
    my $emessage = shift;

    error_log($message);
    print "$emessage\n";
}

1;
