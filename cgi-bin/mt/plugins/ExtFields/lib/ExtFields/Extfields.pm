package ExtFields::Extfields;
use strict;

use base qw( MT::Object );
__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'entry_id' => 'integer not null',
        'blog_id' => 'integer not null',
        'text' => 'text',
        'name' => 'string(255)',
        'label' => 'string(255)',
        'multiple' => 'text',
        'select_item' => 'string(255)',
        'file_path' => 'string(255)',
        'thumbnail' => 'string(255)',
        'file_type' => 'string(255)',
        'mime_type' => 'string(255)',
        'type' => 'string(25)',
        'sort_num' => 'integer',
        'asset_id' => 'integer', # BACKWARD: 'asset'
        'asset' => 'integer', # BACKWARD: for converter
        'status' => 'integer not null',
        'metadata' => 'string(255)',
        'thumb_metadata' => 'string(255)',
        'alternative' => 'text',
        'description' => 'text',
        'transform' => 'integer',
        'compact' => 'integer',
    },
    indexes => {
        'entry_id' => 1,
        'blog_id' => 1,
        'type' => 1,
        'name' => 1,
        'asset_id' => 1, # BACKWARD: 'asset'
        'status' => 1,
    },
    child_of => [ 'MT::Blog', 'MT::Website' ],
    datasource => 'extfields',
    primary_key => 'id',
} );

sub class_label {
    my $plugin = MT->component( 'ExtFields' );
    return $plugin->translate( 'Extra Fields' );
}

sub class_label_plural {
    my $plugin = MT->component( 'ExtFields' );
    return $plugin->translate( 'Extra Fields' );
}

sub blog {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $blog = $r->cache( 'extfields_blog:' . $obj->blog_id );
    return $blog if defined $blog;
    $blog = MT::Blog->load( { id => $obj->blog_id } );
    $r->cache( 'extfields_blog:' . $obj->blog_id, $blog );
    return $blog;
}

sub entry {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $entry = $r->cache( 'extfields_entry:' . $obj->entry_id );
    return $entry if defined $entry;
    $entry = MT::Entry->load( { id => $obj->entry_id } );
    $r->cache( 'extfields_blog:' . $obj->entry_id, $entry );
    return $entry;
}

sub asset {
    my $obj = shift;
    if ( my $asset_id = $obj->asset_id ) {
        my $r = MT::Request->instance;
        my $asset = $r->cache( 'extfields_asset:' . $asset_id );
        return $asset if defined $asset;
        $asset = MT->model( 'asset' )->load( { id => $asset_id } );
        $r->cache( 'extfields_asset:' . $asset_id, $asset );
        return $asset;
    }
}

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    my $entry_id_condition = '> 0';
    if ( defined( $blog_ids ) && scalar( @$blog_ids ) ) {
        return { terms => { entry_id => \$entry_id_condition,
                            blog_id => $blog_ids,
                          },
                 args => undef,
               };
    }
    return { terms => { entry_id => \$entry_id_condition },
             args => undef,
           };
}

1;
