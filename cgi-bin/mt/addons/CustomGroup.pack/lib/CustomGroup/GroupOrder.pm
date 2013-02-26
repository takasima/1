package CustomGroup::GroupOrder;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id'           => 'integer not null auto_increment',
        'order'        => 'integer',
        'group_id'     => 'integer',
        'object_id'    => 'integer',
        'object_class' => 'string(25)',
        'group_class'  => 'string(25)',
        'blog_id'      => 'integer',
    },
    indexes => {
        'order'       => 1,
        'group_id'    => 1,
        'object_id'   => 1,
        'group_class' => 1,
        'blog_id'     => 1,
    },
    child_of    => [ 'CustomGroup::CustomGroup', 'MT::Blog', 'MT::Website' ],
    datasource  => 'grouporder',
    primary_key => 'id',
} );

# sub class_label {
#     my $plugin = MT->component( 'CustomGroup' );
#     return $plugin->translate( 'Order' );
# }
#
# sub class_label_plural {
#     my $plugin = MT->component( 'CustomGroup' );
#     return $plugin->translate( 'Order' );
# }

sub parents {
    my $obj = shift;
    {   group_id => MT->model( 'customgroup' ),
        object_id => {
            relations => {
                key      => 'object_class',
                entry_id => [ MT->model( 'entry' ), MT->model( 'page' ) ],
            }
        }
    };
}

sub restore_parent_ids {
    my $obj = shift;
    my ( $data, $objects ) = @_;
    my $result = 0;
    my $object_id = $data->{ object_id };
    my $group_id = $data->{ group_id };
    my $group_class = $data->{ group_class };
    if ( $object_id && $group_id && $group_class ) {
        my $group = MT->model( $group_class );
        if ( $group && $group->can( 'child_class' ) ) {
            my $child_class = $group->child_class;
            unless ( ref $child_class eq 'ARRAY' ) {
                $child_class = [ $child_class ];
            }
            $group_class = MT->model( $group_class );
            for my $class_name ( @$child_class ) {
                my $class = MT->model( $class_name );
                my $new_obj = $objects->{ $class . '#' . $object_id };
                my $new_group_obj = $objects->{ $group_class . '#' . $group_id };
                if ( $new_obj && $new_group_obj ) {
                    $data->{ group_id } = $new_group_obj->id;
                    $data->{ object_id } = $new_obj->id;
                    $result = 1;
                    last;
                }
            }
        }
    }
    $result;
}

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    if ( defined( $blog_ids ) && scalar( @$blog_ids ) ) {
        return {
            terms => undef,
            args  => {
                'join' => MT->model( 'customgroup' )->join_on(
                    undef,
                    { id => \'= grouporder_group_id',
                      blog_id => $blog_ids,
                    }, {
                      unique => 1,
                    }
                )
            }
        };
    }
    return {
        terms => undef,
        args  => {
            'join' => MT->model( 'customgroup' )->join_on(
                undef,
                { id => \'= grouporder_group_id' },
                { unique => 1 }
            )
        }
    };
#    return { terms => undef, args => undef };
}

1;
