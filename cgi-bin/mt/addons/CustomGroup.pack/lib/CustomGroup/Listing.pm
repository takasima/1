package CustomGroup::Listing;

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

sub _pre_run {
    my ( $cb, $app ) = @_;
    my $menus = MT->registry( 'applications', 'cms', 'menus' );
    my $custom_groups = MT->registry( 'custom_groups' );
    my @groups = keys( %$custom_groups );
    if ( MT->version_id =~ /^5\.0/ ) {
        for my $group ( @groups ) {
            my $class = $custom_groups->object_class;
            $menus->{ $class . ':list_' . $group }->{ mode } = 'list_' . $group;
            $menus->{ $class . ':list_' . $group }->{ view } = [ 'blog', 'website' ];
        }
    }
    if ( my $mode = $app->param( '__mode' ) ) {
        if ( $mode eq 'view' ) {
            my $type = $app->param( '_type' );
            if ( $custom_groups->{ $type } ) {
                my $plugin = MT->component( $custom_groups->{ $type }->{ component } );
                $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
            }
        }
    }
}

sub system_filters {
    my $app = MT->instance();
    my $group = $app->param( '_type' );
    if (! $group ) {
        $group = $app->param( 'datasource' );
    }
    my $custom_groups = MT->registry( 'custom_groups' );
    my $component = $custom_groups->{ $group }->{ component };
    my $plugin = MT->component( $component );
    return unless $plugin;
    my $filters = {
        my_posts => {
            label => $plugin->translate( 'My [_1]', $plugin->translate( $custom_groups->{ $group }->{ name } ) ),
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
    my $group = $app->param( '_type' );
    if (! $group ) {
        $group = $app->param( 'datasource' );
    }
    my $custom_groups = MT->registry( 'custom_groups' );
    my $component = $custom_groups->{ $group }->{ component };
    my $plugin = MT->component( $component );
    return unless $plugin;
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
        additem => {
            label   => 'Settings',
            display => 'optional',
            order   => 250,
            html => sub { settings( @_ ) },
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
            label           => $plugin->translate( 'My [_1]', $plugin->translate( $custom_groups->{ $group }->{ name } ) ),
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
    my $group = $app->param( '_type' );
    if (! $group ) {
        $group = $app->param( 'datasource' );
    }
    my $name = encode_html( $obj->name ) || '...';
    my $args = { _type => $group,
                 blog_id => $obj->blog_id,
                 id => $obj->id,
                };
    if ( my $filter_tag = $obj->filter_tag ) {
        $args->{ filter_tag } = encode_html( $filter_tag );
    }
    if ( my $filter = $obj->filter ) {
        $args->{ filter } = encode_html( $filter );
    }
    if ( my $filter_container = $obj->filter_container ) {
        $args->{ filter_container } = encode_html( $filter_container );
    }
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
    my $group = $app->param( '_type' );
    if (! $group ) {
        $group = $app->param( 'datasource' );
    }
    my $custom_groups = MT->registry( 'custom_groups' );
    my $component = $custom_groups->{ $group }->{ component };
    my $plugin = MT->component( $component );
    return unless $plugin;
    return {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            # code        =>
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => $group },
            order       => 100,
        },
    };
}

sub _list_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $class = $app->param( '_type' );
    $class =~ s/group$//;
    if ( MT->model( $class ) ) {
        $param->{ search_label } = MT->model( $class )->class_label;
        $param->{ search_type } = $class;
    }
}

sub settings {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'CustomGroup' );
    if (! $obj->additem ) {
        return $plugin->translate( 'None' );
    }
    my $addposition = $obj->addposition;
    my $settings;
    if ( $addposition ) {
        $settings = $plugin->translate( 'Add new Object to last' );
    } else {
        $settings = $plugin->translate( 'Add new Object to first' );
    }
    my @sets;
    if ( my $addfiltertag = $obj->addfiltertag ) {
        my $set = $plugin->translate( 'Tag is' );
        $set .= "'$addfiltertag'";
        push ( @sets, $set );
    }
    if ( my $addfilterclass = $obj->addfilterclass ) {
        my $set = $plugin->translate( 'Type is' );
        $addfilterclass = $plugin->translate( $addfilterclass );
        $set .= " '$addfilterclass'";
        push ( @sets, $set );
    }
    if ( $obj->blog->class eq 'website' ) {
        if ( my $addfilter_blog_id = $obj->addfilter_blog_id ) {
            require MT::Blog;
            my $blog = MT::Blog->load( $addfilter_blog_id );
            push ( @sets, $blog->name ) if $blog;
        } else {
            push ( @sets, $plugin->translate( 'website and all blogs' ) );
        }
    }
    if ( my $addfilter_cid = $obj->addfilter_cid ) {
        my $set = $plugin->translate( 'Category / Folder is' );
        require MT::Category;
        if ( my $category = MT::Category->load( $addfilter_cid ) ) {
            my $filterlabal = $category->label;
            $set .= "'$filterlabal'";
            push ( @sets, $set );
        }
    }
    if ( @sets ) {
        my $added = join( ', ', @sets );
        $settings .= "($added)";
    }
    return $settings;
}

1;
