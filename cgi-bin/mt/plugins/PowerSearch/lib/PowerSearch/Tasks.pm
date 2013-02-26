package PowerSearch::Tasks;
use strict;
use warnings;
use base qw( Exporter );
use lib qw( addons/PowerCMS.pack/lib );

our @EXPORT_OK = qw( _update_index );

use English qw(-no_match_vars);
use File::Copy;
use File::Copy::Recursive qw( fcopy rcopy dircopy );

use MT::Util qw( epoch2ts format_ts );
use PowerCMS::Util qw( error_log site_path site_url );
use PowerSearch::Util qw( _get_estcmdpath _get_estcmdindex _get_estfilterpath _get_tempdir _to_hash _timezone );

my $index_tmp    = '';
my $index_remove = '';

sub _update_index {
    my $app    = MT->instance();
    my $plugin = MT->component('PowerSearch');

    eval { require Estraier; };
    if ($EVAL_ERROR) {
        error_log( $plugin->translate('Estraier.pm is not installed. Quit.') );
        return;
    }

    my $fmgr          = MT::FileMgr->new('Local') or die MT::FileMgr->errstr;
    my $index         = _get_estcmdindex()        or return;
    my $estcmdpath    = _get_estcmdpath()         or return;
    my $estfilterpath = _get_estfilterpath()      or return;
    my $tmp_dir       = _get_tempdir()            or return;

    my $do;
    $index_tmp    = File::Spec->catfile( $tmp_dir, "estindex_tmp_r" );
    $index_remove = File::Spec->catfile( $tmp_dir, "estindex_remove_r" );

    unless ( -d $index_tmp ) {
        if ( -d $index ) {
            dircopy( $index, $index_tmp );
            my $updated;
            my @update = MT::Session->load( { kind => 'EU', name => 'EST' } );
            for my $sess (@update) {
                my $path = $sess->data;
                if ( -f $path ) {
                    my $cmd = "$estcmdpath put -cl $index_tmp $path";
                    my $res = system($cmd );
                }
                $sess->remove or die $sess->errstr;
                $updated = 1;
            }
            my @up_files
                = MT::Session->load( { kind => 'EF', name => 'EST' } );
            my $target_files = $plugin->get_config_value('target_files');
            my @extentions = split( /,/, $target_files );

            for my $sess (@up_files) {
                my $f       = $sess->data;
                my $blog_id = $sess->email;
                my $blog    = MT::Blog->load($blog_id);
                unless ( defined $blog ) {
                    $sess->remove or die $sess->errstr;
                    next;
                }

                my $site_url  = site_url($blog);
                my $site_path = site_path($blog);
                my $config_id = 'blog:' . $blog_id;
                my $draft_base
                    = $plugin->get_config_value( 'draftpath', $config_id );
                $draft_base = $plugin->get_config_value('draftpath')
                    unless $draft_base;
                if ($draft_base) {
                    $draft_base
                        = File::Spec->catdir( $site_path, $draft_base );
                }
                if ( -f $f ) {

                    my $file_url  = $f;
                    my $full_path = $f;
                    $site_path = quotemeta($site_path);
                    $file_url =~ s/^$site_path/$site_url/;
                    $file_url =~ s#\\#/#g;
                    my ( $name, $path, $suffix )
                        = File::Basename::fileparse( lc($f), @extentions );
                    if ($suffix) {
                        $suffix =~ s/\.//g;
                        $suffix = lc($suffix);
                        my $fname = _to_hash($full_path);
                        my $ts    = ( stat $full_path )[9];
                        $ts = epoch2ts( $blog, $ts );
                        $ts = format_ts( '%Y-%m-%dT%H:%M:%S', $ts, $blog );
                        my $tz = _timezone($blog);
                        $ts .= $tz;
                        my $draft = "\@uri=$file_url\n";
                        $draft .= "\@cdate=$ts\n";
                        $draft .= "\@mdate=$ts\n";
                        $draft .= "\@blog_id=$blog_id\n";
                        $draft .= "\@suffix=$suffix\n";
                        my $filter_cmd;
                        my $dopt = '-fh';
                        next if $suffix !~ /(xls|doc|ppt|pdf)$/i;

                        if ( $^O eq 'MSWin32' ) {
                            $filter_cmd = File::Spec->catdir( $estfilterpath,
                                'xdoc2txt' );
                            $dopt = '-ft -ic CP932';
                            $draft .= "\@title=$file_url\n";
                        }
                        elsif ( $suffix =~ /(xls|doc|ppt)$/i ) {
                            $filter_cmd = File::Spec->catdir( $estfilterpath,
                                'estfxmsotohtml' );
                        }
                        elsif ( $suffix =~ /pdf$/i ) {
                            $filter_cmd = File::Spec->catdir( $estfilterpath,
                                'estfxpdftohtml' );
                        }
                        my $outpath = File::Spec->catdir( $tmp_dir,
                            "$fname.file.est.tmp" );
                        $filter_cmd
                            .= " $full_path | $estcmdpath draft $dopt > $outpath";
                        my $res   = system($filter_cmd);
                        my $data  = $fmgr->get_data($outpath);
                        my $title = $data;
                        if ( $data =~ m/^.*?\@title=(.*?)\n.*$/s ) {
                            if ( $1 eq $full_path ) {
                                $data
                                    =~ s/(^.*?\@title=)(.*?)(\n.*$)/$1$name\.$suffix$3/s;
                            }
                        }
                        $draft .= $data;
                        if ( -d $draft_base ) {
                            my $outest = File::Spec->catdir( $draft_base,
                                "$fname.file.est" );
                            $fmgr->put_data( $draft, $outest );
                            my $cmd
                                = "$estcmdpath put -cl $index_tmp $outest";
                            my $res = system($cmd);
                            $fmgr->delete($outest);
                        }
                        $fmgr->delete($outpath);
                    }
                }
                $sess->remove or die $sess->errstr;
                $updated = 1;
            }

            my @remove = MT::Session->load( { kind => 'ED', name => 'EST' } );
            for my $sess (@remove) {
                my $path = $sess->data;
                if ( !-f $path ) {
                    my $cmd = "$estcmdpath out -cl $index_tmp $path";
                    my $res = system($cmd );
                }
                $sess->remove or die $sess->errstr;
                $updated = 1;
            }
            if ($updated) {
                move $index,     "$index_remove" or die $!;
                move $index_tmp, $index          or die $!;
                File::Path::rmtree( ["$index_remove"] )
                    if ( -d "$index_remove" );
                $app->log(
                    $plugin->translate(
                        'Update all blog\'s index [_1]', $index
                    )
                );
                $do = 1;
            }
            else {
                File::Path::rmtree( ["$index_tmp"] ) if ( -d "$index_tmp" );
            }
        }
    }
}

END {
    if ( -d $index_tmp ) {
        File::Path::rmtree($index_tmp);
    }
    if ( -d $index_remove ) {
        File::Path::rmtree($index_remove);
    }
}
1;
