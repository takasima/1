package PowerSearch::Callbacks;

use strict;
use warnings;

use MT;
use MT::Session;

use lib qw( lib );
use PowerSearch::Util qw( _to_hash );

########################################################################################
# Add entry archive => ex: draft/<$MTBlogID$>/<$MTEntryID$>.est

# estcmd option:
# gather => estcmd gather [-tr] [-cl] [-ws] [-no] [-fe|-ft|-fh|-fm] [-fx sufs cmd] [-fz] [-fo] [-rm sufs]
# [-ic enc] [-il lang] [-bc] [-lt num] [-lf num] [-pc enc] [-px name] [-aa name value] [-apn|-acc]
# [-xs|-xl|-xh|-xh2|-xh3] [-sv|-si|-sa] [-ss name] [-sd] [-cm] [-cs num] [-ncm] [-kn num] [-um] db [file|dir]
# put => estcmd put [-tr] [-cl] [-ws] [-apn|-acc] [-xs|-xl|-xh|-xh2|-xh3] [-sv|-si|-sa] db [file]
# out => estcmd out [-cl] [-pc enc] db expr

# estcmd extkeys -um casket

########################################################################################

sub _post_delete_asset {
    my ( $cb, $obj, $original ) = @_;
    my $plugin = MT->component('PowerSearch');

    eval { require Estraier };
    unless ($@) {
        my $blog_id         = $obj->blog_id;
        my $obj_id          = $obj->id;
        my $file            = $obj->file_path;
        my $realtime_update = $plugin->get_config_value('realtime_update');
        if ($realtime_update) {
            my $target_files = $plugin->get_config_value('target_files');
            my @extensions = split( /,/, $target_files );
            my ( $name, $path, $suffix )
                = File::Basename::fileparse( $file, @extensions );
            if ($suffix) {
                my $permalink = $obj->url;
                my $id        = _to_hash("UPDATE:EST:$path");
                my $sess      = MT::Session->get_by_key(
                    {   id    => $id,
                        kind  => 'EF',
                        data  => $file,
                        email => $blog_id,
                        name  => 'EST'
                    }
                );
                if ( $sess->start ) {
                    $sess->remove or die $sess->errstr;
                }
                $id   = _to_hash("DELASSET:EST:$file");
                $sess = MT::Session->get_by_key(
                    {   id   => $id,
                        kind => 'ED',
                        data => $permalink,
                        name => 'EST'
                    }
                );
                unless ( $sess->start ) {
                    $sess->start(time);
                    $sess->save or die $sess->errstr;
                }
            }
        }
    }
}

sub _cms_upload_file {
    my ( $cb, %args ) = @_;
    my $plugin = MT->component('PowerSearch');

    eval { require Estraier };
    unless ($@) {
        my $file            = $args{'File'};
        my $blog            = $args{'Blog'};
        my $blog_id         = $blog->id;
        my $realtime_update = $plugin->get_config_value('realtime_update');
        if ($realtime_update) {
            my $target_files = $plugin->get_config_value('target_files');
            my @extensions = split( /,/, $target_files );
            if ( -f $file ) {
                my ( $name, $path, $suffix )
                    = File::Basename::fileparse( $file, @extensions );
                if ($suffix) {
                    my $id   = _to_hash("UPLOAD:EST:$file");
                    my $sess = MT::Session->get_by_key(
                        {   id    => $id,
                            kind  => 'EF',
                            data  => $file,
                            email => $blog_id,
                            name  => 'EST'
                        }
                    );
                    unless ( $sess->start ) {
                        $sess->start(time);
                        $sess->save or die $sess->errstr;
                    }
                }
            }
        }
    }
}

sub _delete_archive {
    my ( $cb, $file, $at, $entry ) = @_;
    my $plugin = MT->component('PowerSearch');

    eval { require Estraier };
    unless ($@) {
        my $realtime_update = $plugin->get_config_value('realtime_update');
        if ($realtime_update) {
            if ( $file =~ /\.est$/ ) {
                my $path      = $file;
                my $blog_id   = $entry->blog_id;
                my $permalink = $entry->permalink;
                my $id        = _to_hash("UPDATE:EST:$path");
                my $sess      = MT::Session->get_by_key(
                    {   id   => $id,
                        kind => 'EU',
                        data => $path,
                        name => 'EST'
                    }
                );
                if ( $sess->start ) {
                    $sess->remove or die $sess->errstr;
                }
                $id   = _to_hash("DELETE:EST:$path");
                $sess = MT::Session->get_by_key(
                    {   id   => $id,
                        kind => 'ED',
                        data => $permalink,
                        name => 'EST'
                    }
                );
                unless ( $sess->start ) {
                    $sess->start(time);
                    $sess->save or die $sess->errstr;
                }
            }
        }
    }
}

sub _build_file {
    my ( $cb, %args ) = @_;
    my $plugin = MT->component('PowerSearch');

    eval { require Estraier };
    unless ($@) {
        my $realtime_update = $plugin->get_config_value('realtime_update');
        if ($realtime_update) {
            my $path    = $args{'File'};
            my $blog    = $args{'Blog'};
            my $entry   = $args{'Entry'};
            my $blog_id = $blog->id;
            if ( $path =~ /\.est$/ ) {
                my $id   = _to_hash("UPDATE:EST:$path");
                my $sess = MT::Session->get_by_key(
                    {   id   => $id,
                        kind => 'EU',
                        data => $path,
                        name => 'EST'
                    }
                );
                unless ( $sess->start ) {
                    $sess->start(time);
                    $sess->save or die $sess->errstr;
                }
            }
        }
    }
}

1;
