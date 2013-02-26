package Link::LinkOrder;
use strict;

use base qw( MT::Object );
__PACKAGE__->install_properties( {
    column_defs => {
        'id'          => 'integer not null auto_increment',
        'order'       => 'integer',
        'group_id'    => 'integer',
        'link_id'     => 'integer',
        'blog_id'     => 'integer',
    },
    indexes => {
        'order'       => 1,
        'group_id'    => 1,
        'link_id'     => 1,
        'blog_id'     => 1,
    },
    child_of    => [ 'Link::LinkGroup', 'MT::Blog', 'MT::Website' ],
    datasource  => 'linkorder',
    primary_key => 'id',
} );

sub class_label {
    my $plugin = MT->component( 'Link' );
    return $plugin->translate( 'Link Order' );
}

sub class_label_plural {
    my $plugin = MT->component( 'Link' );
    return $plugin->translate( 'Link Order' );
}


sub parents {
    my $obj = shift;
    {   link_id => MT->model( 'link' ),
        group_id => MT->model( 'linkgroup' ),
    };
}

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    if ( defined( $blog_ids ) && scalar( @$blog_ids ) ) {
        return {
            terms   => undef,
            args    => {
                'join' => MT->model( 'linkgroup' )->join_on(
                    undef,
                    {   id => \"= linkorder_group_id",
                        blog_id => $blog_ids,
                    }, {
                        unique => 1,
                    }
                )
            }
        };
    }
    return {
        terms   => undef,
        args    => {
            'join' => MT->model( 'linkgroup' )->join_on(
                undef,
                { id => \"= linkorder_group_id", },
                { unique => 1, }
            )
        }
    };
#    return { terms => undef, args => undef };
}

1;
