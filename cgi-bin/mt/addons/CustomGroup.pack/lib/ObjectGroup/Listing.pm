package ObjectGroup::Listing;

use strict;
use MT::Util qw( encode_html );
use CustomGroup::Util qw( permitted_blog_ids );

sub _cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $component = $app->param( 'datasource' );
    if (! $app->user->is_superuser ) {
        my $terms = $load_options->{ terms } || {};
        my @blog_ids = permitted_blog_ids( $app, [ 'administer_website',
                                                   'administer_blog',
                                                   'manage_' . $component ] );
        $terms->{ blog_id } = \@blog_ids;
    }
    return 1;
}

sub system_filters {
    my $app = MT->instance();
    my $filters = {
        my_posts => {
            label => 'My Object Groups',
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
    };
    return $filters;
}

sub list_props {
    my $app = MT->instance();
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        name => {
            base       => '__virtual.title',
            label      => 'Name(Object Count)',
            display    => 'force',
            order      => 200,
            html => sub { group_name( @_ ) },
        },
        author_name => {
            base    => '__virtual.author_name',
            order   => 300,
            display => 'default',
        },
        blog_name => {
            base => '__common.blog_name',
            label =>
                sub { MT->app->blog ? MT->translate( 'Blog Name' ) : MT->translate( 'Website/Blog Name' ) },
            display   => 'default',
            site_name => sub { MT->app->blog ? 0 : 1 },
            order     => 400,
        },
        created_on => {
            base    => '__virtual.created_on',
            display => 500,
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        current_user => {
            base            => '__common.current_user',
            label           => 'My Object Groups',
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
            condition => sub {0},
        },
    };
}

sub group_name {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->name ) || '...';
    my $args = { _type => 'objectgroup',
                 blog_id => $obj->blog_id,
                 id => $obj->id,
                };
    my $edit_link = $app->uri(
        mode => 'view',
        args => $args,
    );
    my $children_count = $obj->children_count;
    return qq{
        <a href="$edit_link">$name</a> ($children_count)
    };
}

sub list_actions {
    my $app = MT->instance();
    return {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            # code        =>
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'objectgroup' },
            order       => 100,
        },
    };
}

1;
