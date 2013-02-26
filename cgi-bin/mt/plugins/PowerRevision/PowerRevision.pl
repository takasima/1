package MT::Plugin::PowerRevision;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );
use XML::Simple;
eval { local ($^W) = 0; require XML::Parser; };
unless ($@) { $XML::Simple::PREFERRED_PARSER = 'XML::Parser'; }
use lib qw( addons/PowerCMS.pack/lib addons/Commercial.pack/lib );
use PowerCMS::Util qw( permitted_blog_ids );
use PowerRevision::Util;
use PowerRevision::Listing;
my $VERSION = '3.6';
my $SCHEMA_VERSION = '0.12';
my $plugin = __PACKAGE__->new( {
    id => 'PowerRevision',
    key => 'powerrevision',
    description => '<__trans phrase="Control the revisions of entry">',
    name => 'PowerRevision',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    version => $VERSION,
    schema_version => $SCHEMA_VERSION,
} );

MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        object_types => {
            entry   => { revision_comment => 'string(255)' },
            session => {
                entry_id => 'integer',
                blog_id  => 'integer',
                modified => 'integer',
                size  => 'integer',
                class => 'string(255)',
            },
            powerrevision => 'PowerRevision::PowerRevision',
        },
        listing_screens => {
            powerrevision => {
                object_label => 'Revision',
                primary => 'object_name',
                default_sort_key => 'modified_on',
                condition => sub { PowerRevision::Util::has_list_permission() },
                view => [ 'user', 'system', 'blog', 'website' ],
            },
        },
        list_properties => {
            powerrevision => {
                id => {
                    base  => '__virtual.id',
                    order => 100,
                },
                object_status => {
                    label   => 'Object',
                    display => 'force',
                    order   => 110,
                    col_class => 'icon',
                    html => sub { PowerRevision::Listing::html_object_status(@_); },
                },
                revision_status => {
                    label   => 'Status',
                    display => 'force',
                    order   => 120,
                    col_class => 'icon',
                    html => sub { PowerRevision::Listing::html_revision_status(@_); },
                },
                recover => {
                    label   => 'Recover',
                    display => 'force',
                    order   => 130,
                    col_class => 'icon',
                    html => sub { PowerRevision::Listing::html_recover(@_) },
                },
                object_name => {
                    base    => '__virtual.title',
                    label   => 'Title',
                    display => 'force',
                    order   => 140,
                    html => sub { PowerRevision::Listing::html_object_name(@_) },
                },
                object_class => {
                    label   => 'Type',
                    display => 'force',
                    order   => 150,
                    col_class => 'string',
                    html => sub { PowerRevision::Listing::html_object_class(@_) },
                    base => '__virtual.single_select',
                    single_select_options => [{
                        label => MT->translate('Entry'),
                        value => 'entry',
                    }, {
                        label => MT->translate('Page'),
                        value => 'page',
                    }],
                    terms => sub {
                        my ( $prop, $args, $db_terms, $db_args ) = @_;
                        $db_terms->{object_class} = $args->{value};
                    },
                },
                blog_name => {
                    base  => '__common.blog_name',
                    label => sub {
                        MT->app->blog ? MT->translate('Blog Name') : MT->translate('Website/Blog Name');
                    },
                    display => 'default',
                    site_name => sub { MT->app->blog ? 0 : 1 },
                    order   => 160,
                },
                author_name => {
                    base  => '__virtual.author_name',
                    label => 'Username',
                    order => 170,
                    display => 'force',
                    html_link => sub {
                        my $prop = shift;
                        my ( $obj, $app, $opts ) = @_;
                        my $author = $obj->author or return undef;
                        return $app->base . $app->uri(
                            mode => 'list',
                            args => {
                                _type   => 'powerrevision',
                                blog_id => $obj->blog_id,
                                filter  => 'author_id',
                                filter_val => $author->id,
                            });
                      }
                },
                class => {
                    auto    => 1,
                    label   => 'Class',
                    display => 'force',
                    order   => 180,
                    html => sub { PowerRevision::Listing::html_class(@_) },
                    base => '__virtual.single_select',
                    single_select_options => sub {
                        my $this_plugins = MT->component('PowerRevision');
                        return [{
                            label => $this_plugins->translate('Workflow'),
                            value => 'workflow',
                        }, {
                            label => $this_plugins->translate('Backup'),
                            value => 'backup',
                        }];
                    },
                    terms => sub {
                        my ( $prop, $args, $db_terms, $db_args ) = @_;
                        $db_terms->{class} = $args->{value};
                    },
                },
                comment => {
                    label => 'Comment for revision',
                    auto  => 1,
                    order => 190,
                },
                obj_auth_on => {
                    base  => '__virtual.created_on',
                    label => 'Publish Date',
                    order => 200,
                },
                modified_on => {
                    base  => '__virtual.modified_on',
                    label => 'Modified On',
                    order => 210,
                },
                view => {
                    label   => 'View',
                    display => 'force',
                    order   => 220,
                    html => sub { PowerRevision::Listing::html_view(@_) },
                },
                object_id => {
                    auto    => 1,
                    label   => 'Object ID',
                    display => 'none',
                },
                object_class_and_class => {
                    label   => 'Object class and class',
                    display => 'none',
                    col     => 'name',
                    base    => '__virtual.single_select',
                    single_select_options => sub {
                        my $this_plugins = MT->component('PowerRevision');
                        return [{
                            label => $this_plugins->translate('Revision for entry and workflow'),
                            value => 'entry_revision_workflow',
                        }, {
                            label => $this_plugins->translate('Revision for entry and backup'),
                            value => 'entry_revision_backup',
                        }, {
                            label => $this_plugins->translate('Revision for page and workflow'),
                            value => 'page_revision_workflow',
                        }, {
                            label => $this_plugins->translate('Revision for page and backup'),
                            value => 'page_revision_backup',
                        }];
                    },
                    terms => sub {
                        my ( $prop, $args, $db_terms, $db_args ) = @_;
                        my $value = $args->{value};
                        if ( $value eq 'entry_revision_workflow' ) {
                            $db_terms->{object_class} = 'entry';
                            $db_terms->{class}        = 'workflow';
                        } elsif ( $value eq 'entry_revision_backup' ) {
                            $db_terms->{object_class} = 'entry';
                            $db_terms->{class}        = 'backup';
                        } elsif ( $value eq 'page_revision_workflow' ) {
                            $db_terms->{object_class} = 'page';
                            $db_terms->{class}        = 'workflow';
                        } elsif ( $value eq 'page_revision_backup' ) {
                            $db_terms->{object_class} = 'page';
                            $db_terms->{class}        = 'backup';
                        }
                    },
                },
                author_id => {
                    label => 'Author',
                    filter_label => 'Author Name',
                    base => '__virtual.string',
                    display => 'none',
                    terms => sub {
                        my ( $prop, $args, $db_terms, $db_args ) = @_;
                        $db_terms->{ author_id } = $args->{ string };
                    },
                },
                status => {
                    label => 'Status',
                    filter_label => 'Status',
                    base => '__virtual.string',
                    display => 'none',
                    terms => sub {
                        my ( $prop, $args, $db_terms, $db_args ) = @_;
                        $db_terms->{ status } = $args->{ string };
                    },
                },
                current_context => {
                    base      => '__common.current_context',
                    condition => sub { 0 },
                },
            },
            entry => {
                revision => {
                    label => 'Revision',
                    order => 207,
                    html  => sub { PowerRevision::Listing::html_revision(@_) },
                },
            },
            page => {
                revision => {
                    label => 'Revision',
                    order => 207,
                    html  => sub { PowerRevision::Listing::html_revision(@_) },
                },
            },
        },
        system_filters => {
            powerrevision => {
                entry_revision => {
                    label => 'Revision for entry',
                    items => [{
                        type => 'object_class',
                        args => { option => 'equal', value => 'entry' },
                    }],
                    order => 100,
                },
                page_revision => {
                    label => 'Revision for page',
                    items => [{
                        type => 'object_class',
                        args => { option => 'equal', value => 'page' },
                    }],
                    order => 110,
                },
                backup => {
                    label => 'Backup',
                    items => [{
                        type => 'class',
                        args =>
                          { option => 'equal', value => 'backup' },
                    }],
                    order => 120,
                },
                workflow => {
                    label => 'Workflow',
                    items => [{
                        type => 'class',
                        args =>
                          { option => 'equal', value => 'workflow' },
                    }],
                    order => 130,
                },
                entry_revision_workflow => sub {
                    my $app = MT->app;
                    return {
                        label => 'Revision for entry and workflow',
                        items => [{
                            type => 'object_class',
                            args => { value => 'entry' },
                        }, {
                            type => 'class',
                            args => { value => 'workflow' },
                        }, (
                            $app->param('object_id')
                            ? ({
                                    type => 'object_id',
                                    args => {
                                        option => 'equal',
                                        value  => $app->param('object_id')
                                    },
                                })
                            : ()
                        )],
                        order => 140,
                    };
                },
                entry_revision_backup => sub {
                    my $app = MT->app;
                    return {
                        label => 'Revision for entry and backup',
                        items => [{
                            type => 'object_class',
                            args => { value => 'entry' },
                        }, {
                            type => 'class',
                            args => { value => 'backup' },
                        }, (
                            $app->param('object_id') ? ({
                                    type => 'object_id',
                                    args => {
                                        option => 'equal',
                                        value  => $app->param('object_id')
                                    },
                                }) : ()
                        )],
                        order => 150,
                    };
                },
                page_revision_workflow => sub {
                    my $app = MT->app;
                    return {
                        label => 'Revision for page and workflow',
                        items => [{
                            type => 'object_class',
                            args => { value => 'page' },
                        }, {
                            type => 'class',
                            args => { value => 'workflow' },
                        }, (
                            $app->param('object_id') ? ({
                                type => 'object_id',
                                args => {
                                    option => 'equal',
                                    value =>
                                      $app->param('object_id')
                                },
                            }): ()
                        )],
                        order => 160,
                    };
                },
                page_revision_backup => sub {
                    my $app = MT->app;
                    return {
                        label => 'Revision for page and backup',
                        items => [{
                            type => 'object_class',
                            args => { value => 'page' },
                        }, {
                            type => 'class',
                            args => { value => 'backup' },
                        }, (
                            $app->param('object_id') ? ({
                                type => 'object_id',
                                args => {
                                    option => 'equal',
                                    value  => $app->param('object_id')
                                },
                            }) : ()
                        )],
                        order => 160,
                    };
                },
            },
        },
        permission_checker => {
            edit_entry => {
                powerrevision => '$powerrevision::PowerRevision::Util::can_edit_entry',
            }
        },
        applications => {
            cms => {
                menus => {
                    'powerrevision' => {
                        label     => 'Revision',
                        order     => 770,
                    },
                    'powerrevision:list_powerrevision_workflow_entry' => {
                        label => 'Workflow(Entry)',
                        mode  => 'list',
                        order => 100,
                        condition => sub { PowerRevision::Util::has_list_permission('entry'); },
                        args => {
                            _type   => 'powerrevision',
                            blog_id => 0,
                            filter_key => 'entry_revision_workflow',
                            filter_val => 'entry_revision_workflow'
                        },
                        view => [ 'user', 'system', 'blog', 'website' ],
                    },
                    'powerrevision:list_powerrevision_backup_entry' => {
                        label => 'Backup(Entry)',
                        mode  => 'list',
                        order => 200,
                        condition => sub { PowerRevision::Util::has_list_permission('entry'); },
                        args => {
                            _type   => 'powerrevision',
                            blog_id => 0,
                            filter_key => 'entry_revision_backup'
                        },
                        view => [ 'user', 'system', 'blog', 'website' ],
                    },
                    'powerrevision:list_powerrevision_workflow_page' => {
                        label => 'Workflow(Page)',
                        mode  => 'list',
                        order => 300,
                        condition => sub { PowerRevision::Util::has_list_permission('page'); },
                        args => {
                            _type => 'powerrevision',
                            blog_id => 0,
                            filter_key => 'page_revision_workflow'
                        },
                        view => [ 'user', 'system', 'blog', 'website' ],
                    },
                    'powerrevision:list_powerrevision_backup_page' => {
                        label => 'Backup(Page)',
                        mode  => 'list',
                        order => 400,
                        condition => sub { PowerRevision::Util::has_list_permission('page'); },
                        args => {
                            _type => 'powerrevision',
                            blog_id => 0,
                            filter_key => 'page_revision_backup'
                        },
                        view => [ 'user', 'system', 'blog', 'website' ],
                    },
                },
                methods => {
                    recover_entry => 'PowerRevision::CMS::_mode_recover_entry',
                    preview_history => 'PowerRevision::CMS::_mode_preview_history',
                    edit_revision => 'PowerRevision::CMS::_mode_edit_revision',
                    select_powerrevision => '$powerrevision::PowerRevision::Plugin::_list_powerrevision',
                    recover_entries => 'PowerRevision::CMS::_mode_recover_entries',
                    cleanup_temporary => 'PowerRevision::CMS::_mode_cleanup_temporary',
                },
                list_actions => {
                    powerrevision => {
                        'delete' => {
                            button => 1,
                            label  => 'Delete',
                            mode   => 'delete',
                            class  => 'icon-action',
                            return_args => 1,
                            args   => { _type => 'powerrevision' },
                            order  => 300,
                        },
                        'recover' => {
                            button => 1,
                            label  => 'Recover',
                            mode   => 'recover_entries',
                            class  => 'icon-action',
                            return_args => 1,
                            args   => { _type => 'powerrevision' },
                            order  => 301,
                            condition => sub { return ( MT->instance()->blog && PowerRevision::Util::can_revision_update() ) },
                        },
                    },
                    entry => {
                        revision_update => {
                            label => 'Revision Update',
                            code  => 'PowerRevision::CMS::_action_revision_update',
                            condition => 'PowerRevision::Util::can_revision_update',
                        },
                    },
                    page => {
                        revision_update => {
                            label => 'Revision Update',
                            code  => 'PowerRevision::CMS::_action_revision_update',
                            condition => 'PowerRevision::Util::can_revision_update',
                        },
                    },
                },
                search_apis => {
                    powerrevision => {
                        handler => '$powerrevision::PowerRevision::Plugin::_search_powerrevision',
                        permission => 'administer_blog,create_post,edit_all_posts,manage_pages',
                        order => 999,
                        label => 'Revision',
                        can_replace => 0,
                        perm_check  => sub {
                            my ($obj) = @_;
                            if ( PowerRevision::Util::has_list_permission() ) {
                                return 1;
                            }
                        },
                        can_search_by_date => 1,
                        date_column => 'modified_on',
                        search_cols => {
                            object_name => 'Title',
                            comment => 'Comment for revision',
                        },
                        setup_terms_args => sub {
                            my ( $terms, $args, $blog_id ) = @_;
                            $terms->{object_ds} = 'entry';
                            my $app = MT->instance();
                            my @permitted_blog_ids = permitted_blog_ids(
                                $app, [ 'administer_blog', 'edit_all_posts',
                                    'publish_post', 'create_post', 'manage_pages' ]);
                            $terms->{blog_id} = \@permitted_blog_ids;
                        },
                        results_table_template => sub {
                            my $plugin_path = $plugin->path;
                            my $results_table_template =
                                '<mt:include name="' . $plugin_path
                              . '/tmpl/include/powerrevision_table.tmpl" component="PowerRevision">';
                            return $results_table_template;
                        },
                    },
                },
            },
        },
        callbacks => {
            'cms_post_save.entry' => {
                handler  => '$powerrevision::PowerRevision::Plugin::_backup_entry',
                priority => 9,
            },
            'cms_post_save.page' => {
                handler  => '$powerrevision::PowerRevision::Plugin::_backup_entry',
                priority => 9,
            },
            'cms_pre_save.entry' => [{
                handler  => '$powerrevision::PowerRevision::Plugin::_author_check_on_release',
                priority => 1,
            }, {
                handler  => '$powerrevision::PowerRevision::Plugin::_save_future',
                priority => 2,
            }, {
                handler  => '$powerrevision::PowerRevision::Plugin::_set_extra_status',
                priority => 1,
            }],
            'cms_pre_save.page' => [{
                handler  => '$powerrevision::PowerRevision::Plugin::_author_check_on_release',
                priority => 1,
            }, {
                handler  => '$powerrevision::PowerRevision::Plugin::_save_future',
                priority => 2,
            }, {
                handler  => '$powerrevision::PowerRevision::Plugin::_set_extra_status',
                priority => 1,
            }],
            'cms_post_delete.blog' => '$powerrevision::PowerRevision::Plugin::_delete_blog',
            'cms_post_delete.entry' => '$powerrevision::PowerRevision::Plugin::_delete_entry_flag',
            'cms_post_delete.page' => '$powerrevision::PowerRevision::Plugin::_delete_entry_flag',
            'MT::App::CMS::template_param.edit_entry' => [{
                handler => '$powerrevision::PowerRevision::Plugin::_transform_edit_entry',
                priority => 2,
            }, {
                handler => '$powerrevision::PowerRevision::Plugin::_edit_entry_param'
            }, {
                handler => '$powerrevision::PowerRevision::Plugin::_cb_tp_edit_entry_entry_prefs',
                priority => 11,
            }],
            'MT::App::CMS::template_source.edit_entry' => '$powerrevision::PowerRevision::Plugin::_recovered_msg',
            'MT::App::CMS::template_output.edit_entry' => {
                handler  => '$powerrevision::PowerRevision::Plugin::_edit_entry_output',
                priority => 1,
            },
            'MT::App::CMS::pre_run' => '$powerrevision::PowerRevision::Plugin::_cb_pre_run',
            'save_revision' => '$powerrevision::PowerRevision::Plugin::_backup_entry',
            'cms_pre_preview' => '$powerrevision::PowerRevision::Plugin::_preview_entry',
            'cms_pre_load_filtered_list.powerrevision' => '$powerrevision::PowerRevision::Plugin::_cb_cms_pre_load_filtered_list_powerrevision',
            'MT::App::CMS::template_source.header' => '$powerrevision::PowerRevision::Plugin::_cb_ts_header',
            'cms_pre_load_filtered_list.entry' => '$powerrevision::PowerRevision::Plugin::_cb_cms_pre_load_filtered_list_entry',
            'MT::App::CMS::entryworkflow_post_change_author' => '$powerrevision::PowerRevision::Plugin::_cb_entryworkflow_post_change_author',
            'MT::App::CMS::entryworkflow_post_sendback' => '$powerrevision::PowerRevision::Plugin::_cb_entryworkflow_post_sendback',
            'cms_post_save.powerrevision' => '$powerrevision::PowerRevision::Plugin::_cb_cms_post_save_powerrevision',
        },
        tasks => {
            cleanup_assets => {
                label => 'cleanup assets',
                frequency => 1,
                code => '$powerrevision::PowerRevision::Tasks::_task_cleanup_assets',
            },
            scheduled_post_from_revision => {
                label => 'scheduled',
                frequency => 1,
                code => '$powerrevision::PowerRevision::Tasks::_task_scheduled_post',
            },
        },
        tags => {
            function => {
                'LatestRevisionValue' => '$powerrevision::PowerRevision::Tags::_hdlr_latest_revision_value',
                'RevisionCount' => '$powerrevision::PowerRevision::Tags::_hdlr_revision_count',
            },
        },
        backup_instructions => {
            powerrevision => {
                skip => 1
            },
        },
    });
}

1;
