package PowerRevision::PowerRevision;
use strict;

use MT::Request;
use MT::Util qw( encode_html );

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( current_user is_windows is_user_can );
use PowerRevision::Util;

use base qw( MT::Object );
__PACKAGE__->install_properties( {
    column_defs => {
        'id'            => 'integer not null auto_increment',
        'object_ds'     => 'string(25)',
        'blog_id'       => 'integer',
        'website_id'    => 'integer',
        'object_name'   => 'string(255)',
        'comment'       => 'string(255)',
        'modified_on'   => 'datetime',
        'obj_auth_on'   => 'datetime', # mt_powerrivision_obj_auth_on ( original object_authored_on )
        'created_on'    => 'datetime',
        'object_id'     => 'integer not null',
        'object_class'  => 'string(25)',
        'status'        => 'integer',
        'author_id'     => 'integer',
        'owner_id'      => 'integer',
        'object_status' => 'integer', # 1 => removed, 2 => exists
        'future_post'   => 'boolean',
        'entry_status'  => 'integer',
        'class'         => 'string(25)',
        'approver_ids'  => 'string(25)',
        'prefs'         => 'text',
    },
    indexes => {
        'object_ds'     => 1,
        'blog_id'       => 1,
        'website_id'    => 1,
        'modified_on'   => 1,
        'obj_auth_on'   => 1,
        'object_id'     => 1,
        'author_id'     => 1,
        'object_class'  => 1,
        'object_status' => 1,
        'entry_status'  => 1,
        'future_post'   => 1,
        'class'         => 1,
        'approver_ids'  => 1,
    },
    child_of    => [ 'MT::Blog', 'MT::Website' ],
    datasource  => 'powerrevision',
    primary_key => 'id',
} );

sub blog {
    my $revision = shift;
    my $r = MT::Request->instance;
    my $blog = $r->cache( 'revision_blog:' . $revision->blog_id );
    return $blog if defined $blog;
    $blog = MT::Blog->load( $revision->blog_id );
    $r->cache( 'revision_blog:' . $revision->blog_id, $blog );
    return $blog;
}

sub remove {
    my $revision = shift;
    if ( $revision eq 'PowerRevision::PowerRevision' ) {
        return 1;
    }
    my $app = MT->instance();
    my $user  = $app->user;
    my $blog = $revision->blog;
    unless ( PowerRevision::Util::has_revision_permission( $user, $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $admin = $user->is_superuser || ( $blog && is_user_can( $blog, $user, 'administer_blog' ) );
    my $edit_all_posts = is_user_can( $blog, $user, 'edit_all_posts' );
    unless ( ( $edit_all_posts ) || ( $admin ) ) {
        unless ( $user->id == $revision->author_id ) {
            return $app->trans_error( 'Permission denied.' );
        }
    }
    my $sep = '/';
    if ( is_windows() ) {
        $sep = '\\\\';
    }
    my $plugin = MT->component( 'PowerRevision' );
    my $backup_dir = PowerRevision::Util::backup_dir();
    my $revision_id;
    eval { $revision_id = $revision->id };
    unless ( $@ ) {
        my $xmlfile = File::Spec->catdir( $backup_dir, $revision_id . '.xml' );
        my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
        if ( $fmgr->exists( $xmlfile ) ) {
            my $assets = File::Spec->catdir( $backup_dir, 'assets', $revision_id );
            if ( $fmgr->exists( $assets ) ) {
                if ( -d $assets ) {
                    opendir( DIR, $assets ) or die "can't opendir $assets: $!";
                    my @files = grep { -f "$assets$sep$_" } readdir( DIR );
                    closedir DIR;
                    my @xmls; my @items;
                    for my $file ( @files ) {
                        if ( $file =~ /^\./ ) {
                            $fmgr->delete( File::Spec->catdir( $assets, $file ) );
                        }
                        my @revs = MT->model( 'powerrevision' )->load( { id => { not => $revision_id },
                                                                         object_id => $revision->object_id,
                                                                         object_ds => 'entry',
                                                                       }
                                                                     );
                        if ( $file =~ /\.xml$/ ) {
                            my $filepath = File::Spec->catdir( $assets, $file );
                            my $xmlsimple = XML::Simple->new();
                            my $asset_hist = $xmlsimple->XMLin( $filepath );
                            my $backuppath = $asset_hist->{ backuppath };
                            $backuppath =~ s/^%b/$backup_dir/;
                            my $ref;
                            for my $rev ( @revs ) {
                                my $comp = File::Spec->catdir( $backup_dir, 'assets', $rev->id, $file );
                                if ( $fmgr->exists( $comp ) ) {
                                    my $c_xmlsimple = XML::Simple->new();
                                    my $c_asset_hist = $xmlsimple->XMLin( $comp );
                                    my $c_backuppath = $c_asset_hist->{ backuppath };
                                    $c_backuppath =~ s/^%b/$backup_dir/;
                                    if ( $c_backuppath eq $backuppath ) {
                                        $ref = 1;
                                        next;
                                    }
                                }
                            }
                            unless ( $ref ) {
                                $fmgr->delete( $backuppath );
                            }
                            $fmgr->delete( $filepath );
                        }
                        my $item_dir = File::Spec->catdir( $assets, 'items' );
                        if ( $fmgr->exists( $item_dir ) ) {
                            opendir( my $dh, $item_dir ) or die "can't opendir $item_dir: $!";
                            my @items_e = grep { -f "$item_dir$sep$_" } readdir( $dh );
                            closedir $dh;
                            unless ( scalar @items_e ) {
                                my $rmdir = rmdir ( $item_dir );
                            }
                        }
                        opendir( my $dh, $assets ) or die "can't opendir $item_dir: $!";
                        my @files_e = grep { -f "$assets$sep$_" } readdir( $dh );
                        closedir $dh;
                        unless ( scalar @files_e ) {
                            my $rmdir = rmdir ( $assets );
                        }
                    }
                }
            }
            $fmgr->delete( $xmlfile );
        }
        my $object_name = encode_html( $revision->object_name );
        my $author_name = encode_html( $user->name );
        $revision->SUPER::remove( @_ );
        $app->log( $plugin->translate ( 'Revision \'[_1]\' (ID:[_2]) deleted by \'[_3]\'', $object_name, $revision_id, $author_name ) );
    }
}

sub class_label {
    my $plugin = MT->component( 'PowerRevision' );
    return $plugin->translate( 'Revision data' );
}

sub class_label_plural {
    my $plugin = MT->component( 'PowerRevision' );
    return $plugin->translate( 'Revision datas' );
}

sub original {
    my $revision = shift;
    my $r = MT::Request->instance;
    my $object = $r->cache( 'revision_original:' . $revision->object_id );
    return $object if defined $object;
    $object = MT->model( $revision->object_class )->load( $revision->object_id );
    $r->cache( 'revision_original:' . $revision->object_id, $object );
    return $object;
}

sub author {
    my $revision = shift;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'revision_author:' . $revision->author_id );
    return $author if defined $author;
    if ( $revision->author_id ) {
        $author = MT->model( 'author' )->load( { id => $revision->author_id } );
    }
    unless ( defined $author ) {
        $author = MT->model( 'author' )->new;
        my $plugin = MT->component( 'PowerRevision' );
        $author->name( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( 'revision_author:' . $revision->author_id, $author );
    return $author;
}

1;
