package CustomObjectConfig::OverRide;
use strict;

sub init {
    # Only for override.
    # Do nothing.
}

no warnings 'redefine';
require CustomFields::Util;
*CustomFields::Util::sync_assets = sub {
    my $obj   = shift;
    my $meta  = CustomFields::Util::get_meta($obj);
    my $class = MT->model( $obj->datasource );
    # PATCH
    if ( $obj->datasource eq 'co' ) {
        $class = MT->model( 'customobject' );
    }
    # /PATCH

    require MT::ObjectAsset;
    my @assets = MT::ObjectAsset->load(
        {   object_id => $obj->id,
            ( $class->has_column('blog_id') )
            ? ( blog_id => $obj->blog_id )
            : (),
            object_ds => $obj->datasource
        }
    );
    my %assets = map { $_->asset_id => $_->id } @assets;

    foreach my $basename ( keys %$meta ) {
        my $text = $meta->{$basename};
        while ( $text
            =~ m!<form[^>]*?\smt:asset-id=["'](\d+)["'][^>]*?>(.+?)</form>!gis
            )
        {
            my $id      = $1;
            my $innards = $2;

            # does asset exist?
            MT->model('asset')->exist( { id => $id } ) or next;

            # reference to an existing asset...
            if ( exists $assets{$id} ) {
                $assets{$id} = 0;
            }
            else {
                my $map = new MT::ObjectAsset;
                $map->blog_id( $obj->blog_id )
                    if $class->has_column('blog_id');
                $map->asset_id($id);
                $map->object_ds( $obj->datasource );
                $map->object_id( $obj->id );
                $map->save;
                $assets{$id} = 0;
            }
        }
    }

    if ( my @old_maps = grep { $assets{ $_->asset_id } } @assets ) {
        if ( UNIVERSAL::isa( $obj, 'MT::Entry' ) ) {
            my $text
                = ( $obj->text || '' ) . "\n" . ( $obj->text_more || '' );
            while ( $text
                =~ m!<form[^>]*?\smt:asset-id=["'](\d+)["'][^>]*?>(.+?)</form>!gis
                )
            {
                my $id      = $1;
                my $innards = $2;

                if ( exists $assets{$id} ) {
                    $assets{$id} = 0;
                }
            }
            @old_maps = grep { $assets{ $_->asset_id } } @old_maps;
        }
        my @old_ids = map { $_->id } @old_maps;
        MT::ObjectAsset->remove( { id => \@old_ids } );
    }
    return 1;
};

1;