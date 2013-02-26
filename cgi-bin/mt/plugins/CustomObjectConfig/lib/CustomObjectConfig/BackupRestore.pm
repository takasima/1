package CustomObjectConfig::BackupRestore;
use strict;

sub init {
    1;
}

no warnings 'redefine';

# for PowerCMS & CustomObject
package MT::ObjectTag;

use CustomObject::Util qw( is_oracle );

*MT::ObjectTag::parents = sub {
    my $obj = shift;
    {   blog_id   => [ MT->model( 'blog' ), MT->model( 'website' ) ],
        tag_id    => MT->model( 'tag' ),
        object_id => {
            relations => {
                key      => 'object_datasource',
                entry_id => [ MT->model( 'entry' ), MT->model( 'page' ) ],
# Patch
                # for PowerCMS
                campaign_id => MT->model( 'campaign' ),
                link_id => MT->model( 'link' ),
                # for CustomObject
                (is_oracle() ? 'co' : 'customobject').'_id' => MT->model( 'customobject' ),
# /Patch
            }
        }
    };
};

sub _restore_id {
    my $obj = shift;
    my ( $key, $val, $data, $objects ) = @_;

    return 0 unless 'ARRAY' eq ref($val);
    return 1 if 0 == $data->{$key};

    my $new_obj;
    my $old_id = $data->{$key};
    foreach (@$val) {
        $new_obj = $objects->{"$_#$old_id"};
        if ( ! $new_obj && $data->{ 'object_datasource' }
            && $data->{ 'object_datasource' } eq (is_oracle() ? 'co' : 'customobject') ) {
            my $custom_objects = MT->registry( 'custom_objects' );
            for my $class ( keys( %$custom_objects ) ) {
                $new_obj = $objects->{ MT->model( $class ) . "#$old_id"};
                last if $new_obj;
            }
        }
        last if $new_obj;
    }
    return 0 unless $new_obj;
    $data->{$key} = $new_obj->id;
    return 1;
}

1;
