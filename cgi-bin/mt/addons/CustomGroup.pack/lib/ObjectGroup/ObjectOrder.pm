package ObjectGroup::ObjectOrder;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'number' => 'integer',
        'object_id' => 'integer',
        'object_ds' => 'string(25)',
        'class' => 'string(25)',
        'objectgroup_id' => 'integer',
        'blog_id' => 'integer',
    },
    indexes => {
        'number' => 1,
        'object_ds' => 1,
        'class' => 1,
        'objectgroup_id' => 1,
        'blog_id' => 1,
    },
    child_of => [ 'ObjectGroup::ObjectGroup', 'MT::Blog', 'MT::Website' ],
    datasource  => 'objectorder',
    primary_key => 'id',
} );

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        objectgroup_id => MT->model( 'objectgroup' ),
        object_id => {
            relations => {
                key         => 'object_ds',
                entry_id    => [ MT->model( 'entry' ), MT->model( 'page' ) ],
                category_id => [ MT->model( 'category' ), MT->model( 'folder' ) ],
                blog_id     => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            }
        }
    };
}

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    if ( defined( $blog_ids ) && scalar( @$blog_ids ) ) {
        return {
            terms => undef,
            args  => {
                'join' => MT->model( 'objectgroup' )->join_on(
                    undef,
                    { id => \'= objectorder_objectgroup_id',
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
            'join' => MT->model( 'objectgroup' )->join_on(
                undef,
                { id => \'= objectorder_objectgroup_id' },
                { unique => 1 }
            )
        }
    };
#    return { terms => undef, args => undef };
}

1;
