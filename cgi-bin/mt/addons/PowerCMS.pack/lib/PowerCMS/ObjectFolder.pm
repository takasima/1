package PowerCMS::ObjectFolder;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id'           => 'integer not null auto_increment',
        'blog_id'      => 'integer',
        'object_ds'    => 'string(255)',
        'object_id'    => 'integer',
        'folder_id'    => 'integer',
    },
    indexes => {
        'blog_id'     => 1,
        'object_ds'   => 1,
        'object_id'   => 1,
        'folder_id'   => 1,
    },
    datasource    => 'objectfolder',
    primary_key   => 'id',
    child_of      => [ 'MT::Blog', 'MT::Website' ],
} );

sub class_label {
    my $plugin = MT->component( 'PowerCMS' );
    return $plugin->translate( 'ObjectFolder' );
}

sub class_label_plural {
    my $plugin = MT->component( 'PowerCMS' );
    return $plugin->translate( 'ObjectFolders' );
}

sub folder {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $folder = $r->cache( 'cache_folder:' . $obj->folder_id );
    return $folder if defined $folder;
    $folder = MT->model( 'folder' )->load( $obj->folder_id );
    $r->cache( 'cache_blog:' . $obj->folder_id, $folder );
    return $folder;
}

sub blog {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $blog = $r->cache( 'cache_blog:' . $obj->blog_id );
    return $blog if defined $blog;
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( 'cache_blog:' . $obj->blog_id, $blog );
    return $blog;
}

sub _cb_folder_pre_remove {
    my ( $cb, $folder ) = @_;
    my $blog_id = $folder->blog_id;
    my @objectfolders = MT->model( 'objectfolder' )->get_by_key( { blog_id => $blog_id,
                                                                   folder_id => $folder->id,
                                                                 }
                                                               );
    for my $objectfolder ( @objectfolders ) {
        $objectfolder->remove;
    }
1;
}

sub _cb_asset_pre_remove {
    my ( $cb, $asset ) = @_;
    my $blog_id = $asset->blog_id;
    my @objectfolders = MT->model( 'objectfolder' )->get_by_key( { blog_id => $blog_id,
                                                                   object_ds => $asset->datasource,
                                                                   object_id => $asset->id,
                                                                 }
                                                               );
    for my $objectfolder ( @objectfolders ) {
        $objectfolder->remove;
    }
1;
}

MT::Folder->add_trigger( pre_remove => \&_cb_folder_pre_remove );
MT::Asset->add_trigger( pre_remove => \&_cb_asset_pre_remove );

1;
