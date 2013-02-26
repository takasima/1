package CustomObject::Listing;

use strict;

use MT::Util qw( encode_html encode_url );
use CustomObject::Util qw( build_tmpl trimj_to permitted_blog_ids site_url is_oracle );

sub _list_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    $param->{ search_label } = MT->translate( 'CustomObject' );
    $param->{ search_type } = 'customobject';
}

sub _cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $component = $app->param( 'datasource' );
    $component = 'customobject' unless $component;
    my $model = MT->model( 'customobject' );
    my $terms = $load_options->{ terms } || {};
#     if ( my $fid = $app->param( 'fid' ) ) {
#         if ( my $status = $model->status_int( $fid ) ) {
#             $terms->{ status } = $status;
#         }
#     }
    if (! $app->user->is_superuser ) {
        # TODO::in Website ( not => 0 ===> id => \@weblogs )
        # my $terms1;
        # $terms1->{ author_id } = $app->user->id;
        # $terms1->{ blog_id } = { not => 0 };
        # $terms1->{ permissions } = { like => "%'administer_%" };
        # my $terms2;
        # $terms2->{ author_id } = $app->user->id;
        # $terms2->{ blog_id } = { not => 0 };
        # $terms2->{ permissions } = { like => "%'manage_" . $component . "'%" };
        # require MT::Permission;
        # my @perms = MT::Permission->load( [ $terms1, '-or', $terms2 ] );
        # my @blog_ids;
        # for my $perm( @perms ) {
        #     push ( @blog_ids, $perm->blog_id );
        # }
        my @blog_ids = permitted_blog_ids( $app, [ 'administer_website', 'administer_blog', 'manage_' . $component ] );
        $terms->{ blog_id } = \@blog_ids;
    }
    return 1;
}

sub _cms_pre_load_filtered_list_group {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $component = $app->param( 'datasource' );
    $component = 'customobjectgroup' unless $component;
    $component =~ s/group$//;
    if (! $app->user->is_superuser ) {
        my $terms = $load_options->{ terms } || {};
        # TODO::in Website ( not => 0 ===> id => \@weblogs )
        # my $terms1;
        # $terms1->{ author_id } = $app->user->id;
        # $terms1->{ blog_id } = { not => 0 };
        # $terms1->{ permissions } = { like => "%'administer_%" };
        # my $terms2;
        # $terms2->{ author_id } = $app->user->id;
        # $terms2->{ blog_id } = { not => 0 };
        # $terms2->{ permissions } = { like => "%'manage_" . $component . "'%" };
        # require MT::Permission;
        # my @perms = MT::Permission->load( [ $terms1, '-or', $terms2 ] );
        # my @blog_ids;
        # for my $perm( @perms ) {
        #     push ( @blog_ids, $perm->blog_id );
        # }
        my @blog_ids = permitted_blog_ids( $app, [ 'administer_website', 'administer_blog', 'manage_' . $component ] );
        $terms->{ blog_id } = \@blog_ids;
    }
    return 1;
}

sub system_filters_customobject {
    my ( $meth, $component ) = @_;
    my $app = MT->instance;
    $component ||= 'customobject';
    my $plugin = MT->component( 'CustomObject' );
    my $model = MT->model( $component );
    my $label = $model->class_label;
    my $config_plugin = MT->component( $component );
    if ( $component eq 'customobject' ) {
        $config_plugin = MT->component( 'CustomObjectConfig' );
    }
    my $filters = {
        my_posts => {
            label => $plugin->translate( 'My [_1]', $label ),
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
        current_website => {
            label => $plugin->translate( '[_1] of this Website', $label ),
            items => sub {
                [ { type => 'current_context' } ];
            },
            order => 1000,
            view => 'website',
        },
    };
    my $status_publishing = 1;
    my $status_draft = 1;
    my $status_review = 1;
    my $status_future = 1;
    my $status_closed = 1;
    if ( my $blog = $app->blog ) {
        $status_publishing = $config_plugin->get_config_value( 'status_publishing', 'blog:'. $blog->id );
        $status_draft = $config_plugin->get_config_value( 'status_draft', 'blog:'. $blog->id );
        $status_review = $config_plugin->get_config_value( 'status_review', 'blog:'. $blog->id );
        $status_closed = $config_plugin->get_config_value( 'status_closed', 'blog:'. $blog->id );
        $status_future = $config_plugin->get_config_value( 'status_future', 'blog:'. $blog->id );
    }
    if ( $status_publishing ) {
        $filters->{ publishing } = {
            label => $plugin->translate( 'Published [_1]', $label ),
            items => [ { type => 'status', args => { value => '2' } } ],
            order => 100,
        };
    }
    if ( $status_draft ) {
        $filters->{ draft } = {
            label => $plugin->translate( 'Unpublished [_1]', $label ),
            items => [ { type => 'status', args => { value => '1' } } ],
            order => 200,
        };
    }
    if ( $status_review ) {
        $filters->{ review } = {
            label => $plugin->translate( 'Unapproved [_1]', $label ),
            items => [ { type => 'status', args => { value => '3' } } ],
            order => 300,
        };
    }
    if ( $status_future ) {
        $filters->{ future } = {
            label => $plugin->translate( 'Scheduled [_1]', $label ),
            items => [ { type => 'status', args => { value => '4' } } ],
            order => 400,
        };
    }
    if ( $status_closed ) {
        $filters->{ closed } = {
            label => $plugin->translate( 'Closed [_1]', $label ),
            items => [ { type => 'status', args => { value => '5' } } ],
            order => 500,
        };
    }
    return $filters;
}

sub system_filters_group {
    my ( $meth, $component ) = @_;
    my $plugin = MT->component( 'CustomObject' );
    if (! $component ) {
        $component = 'customobject';
    }
    my $model = MT->model( $component );
    my $label = $model->class_label;
    my $filters = {
        my_posts => {
            label => $plugin->translate( 'My [_1] Groups', $label ),
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
        current_website => {
            label => $plugin->translate( '[_1] Groups of this Website', $label ),
            items => sub {
                [ { type => 'current_context' } ];
            },
            order => 1000,
            view => 'website',
        },
    };
    return $filters;
}

sub system_filters_tag {
    return {
        customobject => {
            label => 'Tags with CustomObject',
            view  => [ 'blog', 'website' ],
            items => [ { type => 'for_customobject' } ],
            order => 1000,
        },
    };
}

sub list_props_tag {
    return {
        for_customobject => {
            base        => '__virtual.tag',
            filter_tmpl => '<mt:Var name="filter_form_hidden">',
            base_type   => 'hidden',
            label       => 'Tags with CustomObject',
            display     => 'optional',
            obj_class   => 'customobject',
            view        => [ 'blog', 'website' ],
            singleton   => 1,
            terms       => sub {
                my $prop = shift;
                my ( $args, $db_terms, $db_args, $options ) = @_;
                my $blog_id = $options->{ blog_ids };
                my $join = '= objecttag_object_id';
                $db_args->{joins} ||= [];
                require CustomObject::CustomObject;
                push @{ $db_args->{ joins } }, MT->model( 'objecttag' )->join_on(
                    'tag_id',
                    {   object_datasource =>
                            ( is_oracle() ? 'co' : 'customobject' ),
                    },
                    {   group  => [ 'tag_id' ],
                        unique => 1,
                        join   => CustomObject::CustomObject->join_on(
                            undef,
                            {   class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    }
                );
                return;
            },
        },
        customobject_count => {
            label       => 'CustomObjects',
            base        => '__virtual.integer',
            count_class => 'customobject',
            display     => 'default',
            order       => 800,
            col         => 'id',
            obj_class   => 'customobject',
            view        => [ 'blog', 'website' ],
            view_filter => 'none',
            raw         => sub {
                my ( $prop, $obj ) = @_;
                my $blog_id = MT->app->param('blog_id') || 0;
                my $join = '= objecttag_object_id';
                require CustomObject::CustomObject;
                MT->model( 'objecttag' )->count(
                    {   ( $blog_id ? ( blog_id => $blog_id ) : () ),
                        tag_id            => $obj->id,
                        object_datasource => ( is_oracle() ? 'co' : 'customobject' ),
                    },
                    {   join => CustomObject::CustomObject->join_on(
                            undef,
                            {   class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    }
                );
            },
            html_link => sub {
                my ( $prop, $obj, $app ) = @_;
                require CustomObject::Plugin;
                if (! CustomObject::Plugin::_customobject_permission( $app->blog, $prop->{ obj_class } ) ) {
                    return;
                }
                # $app->can_do( 'access_to_' . $prop->entry_class . '_list' )
                #     || return;
                return $app->uri(
                    mode => 'list',
                    args => {
                        _type      => $prop->{ obj_class },
                        class      => $prop->{ obj_class },
                        blog_id    => $app->param( 'blog_id' ) || 0,
                        filter     => 'tag',
                        filter_val => $obj->name,
                    },
                );
            },
            bulk_sort => sub {
                my $prop = shift;
                my ( $objs, $options ) = @_;
                my $join = '= objecttag_object_id';
                my $iter = MT->model( 'objecttag' )->count_group_by(
                    {   (   scalar @{ $options->{ blog_ids } || [] }
                            ? ( blog_id => $options->{ blog_id } )
                            : ()
                        ),
                        object_datasource => 'customobject',
                    },
                    {   sort      => 'cnt',
                        direction => 'ascend',
                        group     => [ 'tag_id' ],
                        join      => CustomObject::CustomObject->join_on(
                            undef,
                            {   class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    },
                );
                my %counts;
                while ( my ( $cnt, $id ) = $iter->() ) {
                    $counts{ $id } = $cnt;
                }
                return sort {
                    ( $counts{ $a->id } || 0 ) <=> ( $counts{ $b->id } || 0 )
                } @$objs;
            },
        },
    };
}

sub list_actions {
    my ( $meth, $component ) = @_;
    my $app = MT->instance;
    if (! $component ) {
        $component = 'customobject';
    }
    my $config_plugin = MT->component( $component );
    if ( $component eq 'customobject' ) {
        $config_plugin = MT->component( 'CustomObjectConfig' );
    }
    my $actions = {
        add_tags => {
            label       => 'Add Tags...',
            # code        =>
            mode        => 'add_tags_to_customobject',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component, _type => 'customobject' },
            order       => 600,
            input         => 1,
            input_label   => 'Tags to add to selected CustomObjects:',
        },
        remove_tags => {
            label       => 'Remove Tags...',
            # code        =>
            mode        => 'remove_tags_to_customobject',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component, _type => 'customobject' },
            order       => 700,
            input         => 1,
            input_label   => 'Tags to remove from selected CustomObjects:',
        },
        'delete' => {
            button      => 1,
            label       => 'Delete',
            # code        =>
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component, _type => 'customobject' },
            order       => 300,
        }
    };
    my $status_publishing = 1;
    my $status_draft = 1;
    my $status_review = 1;
    my $status_future = 1;
    my $status_closed = 1;
    if ( my $blog = $app->blog ) {
        $status_publishing = $config_plugin->get_config_value( 'status_publishing', 'blog:'. $blog->id );
        $status_draft = $config_plugin->get_config_value( 'status_draft', 'blog:'. $blog->id );
        $status_review = $config_plugin->get_config_value( 'status_review', 'blog:'. $blog->id );
        $status_closed = $config_plugin->get_config_value( 'status_closed', 'blog:'. $blog->id );
        $status_future = $config_plugin->get_config_value( 'status_future', 'blog:'. $blog->id );
    }
    if ( $status_publishing ) {
        $actions->{ publish_customobjects } = {
            button      => 1,
            label       => 'Publish',
            # code        =>
            mode        => 'publish_customobjects',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component },
            order       => 100,
        };
    }
    if ( $status_draft ) {
        $actions->{ unpublish_customobjects } = {
            label       => 'Draft',
            # code        =>
            mode        => 'unpublish_customobjects',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component },
            order       => 200,
        };
    }
    if ( $status_closed ) {
        $actions->{ closed_customobjects } = {
            label       => 'Closed',
            # code        =>
            mode        => 'closed_customobjects',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component },
            order       => 400,
        };
    }
    if ( $status_review ) {
        $actions->{ review_customobjects } = {
            label       => 'Review',
            # code        =>
            mode        => 'review_customobjects',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component },
            order       => 300,
        };
    }
    return $actions;
}

sub list_props {
    my ( $meth, $component ) = @_;
    my $app = MT->instance;
    if (! $component ) {
        $component = 'customobject';
    }
    my $plugin = MT->component( $component );
    my $config_plugin = $plugin;
    if ( $component eq 'customobject' ) {
        $config_plugin = MT->component( 'CustomObjectConfig' );
    }
    my $option_body = 'default';
    my $option_keywords = 'default';
    my $option_folder = 'default';
    my $option_authored_on_date = 'default';
    my $option_period_on_date = 'default';
    if ( my $blog = $app->blog ) {
        my $display_options = $config_plugin->get_config_value( 'display_options', 'blog:'. $blog->id );
        if ( $display_options ) {
            my @opt = split( /,/, $display_options );
            if (! grep( /^body$/, @opt ) ) {
                $option_body = 'none';
            }
            if (! grep( /^keywords$/, @opt ) ) {
                $option_keywords = 'none';
            }
            if (! grep( /^folder$/, @opt ) ) {
                $option_folder = 'none';
            }
            if (! grep( /^authored_on_date$/, @opt ) ) {
                $option_authored_on_date = 'none';
            }
            if (! grep( /^period_on_date$/, @opt ) ) {
                $option_period_on_date = 'none';
            }
        }
    }
    my $obj = MT->model( $component );
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        name => {
            base       => '__virtual.title',
            label      => 'Name',
            display    => 'force',
            order      => 200,
            html => sub { name( @_ ) },
        },
        body => {
            auto       => 1,
            display    => $option_body,
            label      => 'Body',
            order      => 250,
            html => sub {
                my ( $prop, $obj, $app ) = @_;
                my $body = encode_html( $obj->body ) || '';
                if ( $body ) {
                    $body = trimj_to( $body, 6, '...' );
                }
                return $body;
            },
        },
        keywords => {
            auto       => 1,
            display    => $option_keywords,
            label      => 'Keywords',
            order      => 250,
            html => sub {
                my ( $prop, $obj, $app ) = @_;
                my $keywords = encode_html( $obj->keywords ) || '';
                if ( $keywords ) {
                    $keywords = trimj_to( $keywords, 6, '...' );
                }
                return $keywords;
            },
        },
        category_id => {
            auto       => 1,
            display    => $option_folder,
            label      => 'Folder',
            col_class  => 'author',
            order      => 210,
            html => sub {
                my ( $prop, $obj, $app ) = @_;
                my $folder_path = $obj->folder_path;
                unless ( $folder_path ) {
                    return MT->translate( '(root)' );
                }
                my $folder = pop( @$folder_path );
                return $folder->label;
            },
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
            display => 'none',
        },
        authored_on => {
            auto       => 1,
            display    => $option_authored_on_date,
            label      => 'Publish Date',
            use_future => 1,
            order      => 500,
        },
        period_on => {
            auto       => 1,
            display    => $option_period_on_date,
            label      => 'End date',
            use_future => 1,
            order      => 550,
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        status => {
            auto  => 1,
            label => 'Status',
            order => 700,
            html => sub { status( @_ ) },
        },
        tag          => { base => '__virtual.tag', tag_ds => 'customobject' },
        current_user => {
            base            => '__common.current_user',
            label           => $plugin->translate( 'My ' . $obj->class_plural ),
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
        },
    };
}

sub list_group_props {
    my ( $meth, $component ) = @_;
    if (! $component ) {
        $component = 'customobject';
    }
    my $plugin = MT->component( $component );
    my $base = MT->component( 'CustomObject' );
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        name => {
            base       => '__virtual.title',
            label      => $base->translate( 'Name(Object Count)' ),
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
            label           => $plugin->translate( 'My ' . $plugin->name . ' Groups' ),
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
        },
    };
}

sub list_group_actions {
    my ( $meth, $component ) = @_;
    if (! $component ) {
        $component = 'customobject';
    }
    return {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            # code        =>
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { class => $component, _type => $component },
            order       => 100,
        },
    };
}

sub content_actions {
    my ( $meth, $component ) = @_;
    if (! $component ) {
        $component = 'customobject';
    }
    my $app = MT->instance;
    my $plugin = MT->component( $component );
    my $model = MT->model( $component );
    my $uploader = <<MTML;
    </a>
<__trans_section component="$component">
    <a href="javascript:void(0);" class="icon-left icon-action" onclick="return upload_csv()"><__trans phrase="Import from CSV"></a>
        <form method="post" style="display:inline" action="<mt:var name="mt_url">" enctype="multipart/form-data" id="upload_customobject_csv">
        <input type="hidden" name="blog_id" value="<mt:var name="blog_id">" />
        <input type="hidden" name="__mode" value="upload_customobject_csv" />
        <input type="hidden" name="class" value="<mt:var name="class">" />
        <input type="hidden" name="return_args" value="<mt:var name="return_args" escape="html">" />
        <input type="hidden" name="magic_token" value="<mt:var name="magic_token">" />
        <span id="csv" style="display:none;">
        <input onchange="file_select()" style="font-size:11px;" type="file" name="file" id="file" />
        <a href="javascript:void(0)" style="display:none" id="send_csv" onclick="return upload_csv()"><__trans phrase="Send"></a>
        &nbsp;&nbsp; </span>
        </form>
    <a>
</__trans_section>
MTML
    if ( $app->blog ) {
        my %args = ( blog => $app->blog );
        my %params = ( class => $component,
                       blog_id => $app->blog->id,
                       magic_token => $app->current_magic(),
                       return_args => $app->make_return_args,
                     );
        $uploader = build_tmpl( $app, $uploader, \%args, \%params );
    }
    return {
        'download_customobject_csv' => {
            mode        => 'download_customobject_csv',
            class       => 'icon-download',
            label       => 'Download CSV',
            return_args => 1,
            condition => sub { MT->app->blog ? 1 : 0 },
            order       => 100,
            args        => { class => $component },
            confirm_msg => sub {
                $plugin->translate( 'Are you sure you want to download all [_1]?', $plugin->translate( $model->class_label ) );
            },
        },
        'upload_customobject_csv' => {
            class       => 'icon-none',
            label       => $uploader,
            condition => sub { MT->app->blog ? 1 : 0 },
            order       => 200,
        },
    };
}

sub name {
    my ( $prop, $obj, $app ) = @_;
    my $icon = status_icon( $prop, $obj, $app );
    my $name = encode_html( $obj->name ) || '...';
    my $edit_link = $app->uri(
        mode => 'view',
        args => {
            _type => 'customobject',
            class => $obj->class,
            blog_id => $obj->blog_id,
            id => $obj->id,
        }
    );
    my $permalink = $obj->permalink;
    my $view_link;
    if ( $permalink && $obj->status == 2 ) {
        $permalink = encode_html( $permalink );
        my $icon_url = MT->static_path . 'images/status_icons/view.gif';
        my $icon_alt = MT->translate( 'View' );
        $view_link = qq{
            <a href="$permalink" target="_blank"><img src="$icon_url" width="13" height="9" alt="$icon_alt" /></a>
        }
    }
    # TODO / Check permission
    return qq{
        $icon <a href="$edit_link">$name</a> $view_link
    };
}

sub group_name {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->name ) || '...';
    my $args = { _type => 'customobjectgroup',
                 class => $obj->class,
                 blog_id => $obj->blog_id,
                 id => $obj->id,
                };
    if ( my $filter_tag = $obj->filter_tag ) {
        $args->{ filter } = 'tag';
        $args->{ filter_tag } = encode_html( $filter_tag );
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

sub settings {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'CustomObject' );
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
    if ( $obj->blog->class eq 'website' ) {
        if ( my $addfilter_blog_id = $obj->addfilter_blog_id ) {
            require MT::Blog;
            my $blog = MT::Blog->load( $addfilter_blog_id );
            push ( @sets, $blog->name ) if $blog;
        } else {
            push ( @sets, $plugin->translate( 'website and all blogs' ) );
        }
    }
    if ( @sets ) {
        my $added = join( ', ', @sets );
        $settings .= "($added)";
    }
    return $settings;
}

sub author {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->author->nickname );
}

sub status {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = $obj->plugin;
    my $status = $obj->status;
    my $alt = $plugin->translate( $obj->status_text );
    my $icon = status_icon( $prop, $obj, $app );
    return $icon . " " . $alt;
}

sub status_icon {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = $obj->plugin;
    my $status = $obj->status;
    my $alt = $plugin->translate( $obj->status_text );
    my $gif;
    if ( $status == $obj->HOLD ) {
        $gif = 'draft.gif';
    } elsif ( $status == $obj->RELEASE ) {
        $gif = 'success.gif';
    } elsif ( $status == $obj->FUTURE ) {
        $gif = 'future.gif';
    } elsif ( $status == $obj->REVIEW ) {
        $gif = 'warning.gif';
    } elsif ( $status == $obj->CLOSED ) {
        $gif = 'close.gif';
    }
    my $url = MT->static_path . 'images/status_icons/' . $gif;
    my $icon = '<img width="9" height="9" alt="' . $alt . '" src="';
    $icon .= $url . '" />';
    return $icon;
}

1;
