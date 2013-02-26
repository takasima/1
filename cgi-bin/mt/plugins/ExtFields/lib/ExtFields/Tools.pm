package ExtFields::Tools;
use strict;

sub converter {
    my @extfields = MT->model( 'extfields' )->load();
    for my $extfield ( @extfields ) {
        my $asset_id = $extfield->{ column_values }->{ asset };
        if ( $asset_id && $asset_id =~ /^[0-9]{1,}$/ ) {
            my $asset = MT->model( 'asset' )->load( { id => $asset_id } );
            if ( $asset ) {
                $extfield->asset_id( $asset->id );
                $extfield->asset( undef );
                $extfield->save or die $extfield->errstr;
            }
        }
    }
}

1;