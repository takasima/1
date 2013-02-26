package ContactForm::Listing;

use strict;

use MT::Util qw( encode_html encode_url remove_html );
use MT::I18N qw( substr_text length_text );
use ContactForm::Util qw( build_tmpl permitted_blog_ids );

sub _cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $model = MT->model( 'contactformgroup' );
    my $terms = $load_options->{ terms } || {};
#     if ( $model && ( my $fid = $app->param( 'fid' ) ) ) {
#         if ( my $status = $model->status_int( $fid ) ) {
#             $terms->{ status } = $status;
#         }
#     }
    if (! $app->user->is_superuser ) {
        # my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        # my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_contactform'%" } );
        # require MT::Permission;
        # my @perms = MT::Permission->load( [ \%terms1, '-or', \%terms2 ] );
        # my @blog_ids;
        # for my $perm( @perms ) {
        #     push ( @blog_ids, $perm->blog_id );
        # }
        # $terms->{ blog_id } = \@blog_ids;
        my @blog_ids = permitted_blog_ids( $app, [ 'administer_website', 'administer_blog', 'manage_contactform' ] );
        $terms->{ blog_id } = \@blog_ids;
    }
}

sub _cms_pre_load_filtered_list_feedback {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $model = MT->model( 'feedback' );
    my $terms = $load_options->{ terms } || {};
#     if ( $model && ( my $fid = $app->param( 'fid' ) ) ) {
#         if ( $fid eq '_object' ) {
#         } else {
#             if ( my $status = $model->status_int( $fid ) ) {
#                 $terms->{ status } = $status;
#             }
#         }
#     }
    if (! $app->user->is_superuser ) {
        # my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        # my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_form_feedback'%" } );
        # require MT::Permission;
        # my @perms = MT::Permission->load( [ \%terms1, '-or', \%terms2 ] );
        # my @blog_ids;
        # for my $perm( @perms ) {
        #     push ( @blog_ids, $perm->blog_id );
        # }
        # $terms->{ blog_id } = \@blog_ids;
        my @blog_ids = permitted_blog_ids( $app, [ 'administer_website', 'administer_blog', 'manage_form_feedback' ] );
        $terms->{ blog_id } = \@blog_ids;
    }
}

sub system_filters {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
    my $label = $plugin->translate( 'Forms' );
    my $filters = {
        my_posts => {
            label => $plugin->translate( 'My Forms', $label ),
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
        publishing => {
            label => $plugin->translate( 'Published [_1]', $label ),
            items => [ { type => 'status', args => { value => '2' } } ],
            order => 100,
        },
        draft => {
            label => $plugin->translate( 'Unpublished [_1]', $label ),
            items => [ { type => 'status', args => { value => '1' } } ],
            order => 200,
        },
        review => {
            label => $plugin->translate( 'Unapproved [_1]', $label ),
            items => [ { type => 'status', args => { value => '3' } } ],
            order => 300,
        },
        future => {
            label => $plugin->translate( 'Scheduled [_1]', $label ),
            items => [ { type => 'status', args => { value => '4' } } ],
            order => 400,
        },
        closed => {
            label => $plugin->translate( 'Closed [_1]', $label ),
            items => [ { type => 'status', args => { value => '5' } } ],
            order => 500,
        }
    };
    return $filters;
}

sub system_filters_feedback {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
    my $model = $app->param( 'model' );
    my $class_label_plural = MT->model( 'feedback' )->class_label_plural;
    my $form_label = MT->model( 'contactformgroup' )->class_label;
    my $object_id = $app->param( 'object_id' );
    my $form_id = $app->param( 'form_id' );
    my $created_by = $app->param( 'created_by' );
    my $owner_id = $app->param( 'owner_id' );
    my $object_label;
    if ( $model && $object_id ) {
        my $object = MT->model( $model )->load( $object_id );
        if ( $object ) {
            if ( $object->has_column( 'title' ) ) {
                $object_label = $object->title;
            } elsif ( $object->has_column( 'name' ) ) {
                $object_label = $object->name;
            } elsif ( $object->has_column( 'label' ) ) {
                $object_label = $object->label;
            }
        }
    }
    if ( $object_label ) {
        $object_label = encode_html( $object_label );
        $object_label = $plugin->translate( 'Feedback for Object \'[_1]\'', $object_label );
    } else {
        $object_label = '(Unknown)';
    }
    my $filters = {
        unapproval => {
            label => $plugin->translate( 'Unapproval Feedback' ),
            items => [ { type => 'status', args => { value => '1' } } ],
            order => 100,
        },
        approval => {
            label => $plugin->translate( 'Approval Feedback' ),
            items => [ { type => 'status', args => { value => '2' } } ],
            order => 200,
        },
        flagged => {
            label => $plugin->translate( 'Flagged Feedback' ),
            items => [ { type => 'status', args => { value => '3' } } ],
            order => 300,
        },
    # _object => {
    #     label => $object_label,
    #     items => [
    #         { type => 'model', args => { value => $model } },
    #         { type => 'object_id', args => { value => $object_id } },
    #     ],
    #     order => 400,
    # },
    };
    if ( $model && $object_id ) {
        $filters->{ _object } = {
            label => $object_label,
            items => [
                { type => 'model', args => { value => $model } },
                { type => 'object_id', args => { value => $object_id } },
            ],
            order => 400,
        };
    }
    if ( $form_id ) {
        my $form = MT->model( 'contactformgroup' )->load( $form_id );
        my $form_name;
        if (! $form ) {
            $form_name = $plugin->translate( '(Unknown)' );
        } else {
            $form_name = $form->name;
        }
        $filters->{ _form_id } = {
            label => $plugin->translate( '[_1] where [_2] is [_3]', $class_label_plural, $form_label, $form_name ),
            items => [
                { type => 'contactform_group_id', args => { value => $form_id } },
            ],
            order => 400,
        };
    }
    if ( $owner_id || $created_by ) {
        my $user_id;
        my $user_name;
        if ( $owner_id ) {
            $user_id = $owner_id;
        } else {
            $user_id = $created_by;
        }
        my $author = MT->model( 'author' )->load( $user_id );
        if (! $author ) {
            $user_name = $plugin->translate( '(Unknown)' );
        } else {
            $user_name = $author->name;
        }
        if ( $owner_id ) {
            my $label = $plugin->translate( 'Owner' );
            $filters->{ _owner_id } = {
                label => $plugin->translate( '[_1] where [_2] is [_3]', $class_label_plural, $label, $user_name ),
                items => [
                    { type => 'owner_id', args => { value => $owner_id } },
                ],
                order => 500,
            };
        }
        if ( $created_by ) {
            my $label = $plugin->translate( 'Author' );
            $filters->{ _created_by } = {
                label => $plugin->translate( '[_1] where [_2] is [_3]', $class_label_plural, $label, $user_name ),
                items => [
                    { type => 'created_by', args => { value => $created_by } },
                ],
                order => 500,
            };
        }
    }
    return $filters;
}

sub list_props {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
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
        type => {
            label      => 'Type',
            display    => 'force',
            order      => 250,
            html => sub { type( @_ ) },
        },
        default => {
            label      => 'Default',
            auto       => 1,
        },
        required => {
            label      => 'Required',
            auto       => 1,
            html => sub { required( @_ ) },
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
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        current_user => {
            base            => '__common.current_user',
            label           => $plugin->translate( 'My Form Elements' ),
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
            condition => sub {0},
        },
    };
}

sub list_props_group {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
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
        feedback_count => {
            display    => 'default',
            label      => 'Posts',
            order      => 250,
            html => sub { feedback_count( @_ ) },
        },
        author_name => {
            base    => '__virtual.author_name',
            order   => 300,
            display => 'default',
        },
        author_id => {
            base  => '__virtual.id',
            label => 'Author ID',
            order   => 305,
            display => 'none',
        },
        blog_name => {
            base => '__common.blog_name',
            label =>
                sub { MT->app->blog ? MT->translate( 'Blog Name' ) : MT->translate( 'Website/Blog Name' ) },
            display   => 'default',
            site_name => sub { MT->app->blog ? 0 : 1 },
            order     => 400,
        },
        status => {
            auto => 1,
            label => 'Status',
            order => 500,
            html => sub { status( @_ ) },
        },
        created_on => {
            base    => '__virtual.created_on',
            display => 'none',
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        current_user => {
            base            => '__common.current_user',
            label           => $plugin->translate( 'My Forms' ),
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
            condition => sub {0},
        },
    };
}

sub list_props_feedback {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        identifier => {
            auto       => 1,
            display    => 'optional',
            label      => 'Identifier',
            order      => 200,
        },
        status => {
            auto       => 1,
            display    => 'optional',
            label      => 'Status',
            order      => 400,
            html       => sub { feedback_status( @_ ) },
        },
        value => {
            display    => 'force',
            label      => 'Value',
            order      => 300,
            html       => sub { feedback_get_string( @_ ) },
        },
        memo => {
            auto       => 1,
            display    => 'optional',
            label      => 'Memo',
            order      => 500,
        },
        form_id => {
            display    => 'force',
            label      => 'Form',
            order      => 500,
            html       => sub { feedback_form_name( @_ ) },
        },
        owner_id => {
            auto       => 1,
            display    => 'optional',
            label      => 'Owner',
            order      => 530,
            html       => sub { feedback_owner( @_ ) },
        },
        created_by => {
            auto       => 1,
            display    => 'optional',
            label      => 'Author',
            order      => 540,
            html       => sub { feedback_author( @_ ) },
        },
        email => {
            auto       => 1,
            display    => 'default',
            label      => 'Email',
            order      => 550,
            html       => sub { feedback_email( @_ ) },
        },
        object_name => {
            display    => 'force',
            label      => 'Object',
            order      => 560,
            html       => sub { feedback_object( @_ ) },
            base       => '__virtual.string',
            col_class  => 'string',
            terms => sub {
                my ( $prop, $args, $db_terms, $db_args ) = @_;
                my $app = MT->instance;
                my $blog_id = $app->blog ? $app->blog->id : undef;
                my $option = $args->{ option };
                my $query  = $args->{ string };
                if ( 'contains' eq $option ) {
                    $query = { like => "%$query%" };
                }
                elsif ( 'not_contains' eq $option ) {
                    $query = { not_like => "%$query%" };
                }
                elsif ( 'beginning' eq $option ) {
                    $query = { like => "$query%" };
                }
                elsif ( 'end' eq $option ) {
                    $query = { like => "%$query" };
                }
                $db_args->{ 'join' } =
                    MT->model( 'entry' )->join_on( undef,
                                                  { id => \'= feedback_object_id',
                                                    ( $blog_id ? ( blog_id => $blog_id ) : () ),
                                                    title => $query,
                                                  },
                                                  { no_class => 1 },
                                                );
                return;
            },
        },
        blog_name => {
            base => '__common.blog_name',
            label =>
                sub { MT->app->blog ? MT->translate( 'Blog Name' ) : MT->translate( 'Website/Blog Name' ) },
            display   => 'default',
            site_name => sub { MT->app->blog ? 0 : 1 },
            order     => 600,
        },
        created_on => {
            label => 'Post On',
            display    => 'force',
            base    => '__virtual.created_on',
            order => 700,
        },
        object_id => {
            auto => 1,
            display => 'none',
            filter_editable => 0,
        },
        model => {
            auto => 1,
            display => 'none',
            filter_editable => 0,
        },
        contactform_group_id => {
            auto => 1,
            display => 'none',
            filter_editable => 0,
        },
        current_context => {
            base      => '__common.current_context',
            condition => sub {0},
        },
    };
}

sub feedback_object {
    my ( $prop, $obj, $app ) = @_;
    my $object_name = encode_html( $obj->object_name );
    my $object_label = $obj->object_label;
    my $edit_link = $app->uri(
        mode => 'list',
        args => {
            _type => 'feedback',
            filter_key => '_object',
            blog_id => $obj->blog_id,
            object_id => $obj->object_id,
            model => $obj->model,
        }
    );
    return qq{
        <a href="$edit_link">$object_name</a> ($object_label)
    };
}

sub feedback_get_string {
    my ( $prop, $obj, $app ) = @_;
    my $get_string = remove_html( $obj->get_string ) || '...';
    $get_string = substr_text( $get_string, 0, 15 ) . ( length_text( $get_string ) > 15 ? "..." : "" );
    my $icon = status_icon_feedback( $prop, $obj, $app );
    my $edit_link = $app->uri(
        mode => 'view',
        args => {
            _type => 'feedback',
            blog_id => $obj->blog_id,
            id => $obj->id,
        }
    );
    return qq{
        $icon <a href="$edit_link">$get_string</a>
    };
}

sub feedback_form_name {
    my ( $prop, $obj, $app ) = @_;
    my $object_name = $obj->form_name;
    my $list_link = $app->uri(
        mode => 'list',
        args => {
            _type => 'feedback',
            filter_key => '_form_id',
            blog_id => $obj->blog_id,
            form_id => $obj->contactform_group_id,
        }
    );
    return qq{
        <a href="$list_link">$object_name</a>
    };
    # return $obj->form_name;
}

sub feedback_author {
    my ( $prop, $obj, $app ) = @_;
    my $author = $obj->author( 'created_by' );
    my $author_name = $author->nickname;
    my $list_link = $app->uri(
        mode => 'list',
        args => {
            _type => 'feedback',
            filter_key => '_created_by',
            blog_id => $obj->blog_id,
            created_by => $obj->created_by,
        }
    );
    if ( $author->id ) {
        return qq{
            <a href="$list_link">$author_name</a>
        };
    } else {
        return $author_name;
    }
}

sub feedback_owner {
    my ( $prop, $obj, $app ) = @_;
    my $author = $obj->author( 'owner_id' );
    my $author_name = $author->nickname;
    my $list_link = $app->uri(
        mode => 'list',
        args => {
            _type => 'feedback',
            filter_key => '_owner_id',
            blog_id => $obj->blog_id,
            owner_id => $obj->owner_id,
        }
    );
    if ( $author->id ) {
        return qq{
            <a href="$list_link">$author_name</a>
        };
    } else {
        return $author_name;
    }
}

# value memo form_name Owner object remote_ip

sub list_actions {
    my $actions = {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            # code        =>
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'contactform' },
            order       => 300,
        }
    };
    return $actions;
}

sub list_actions_group {
    my $actions = {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            # code        =>
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'contactformgroup' },
            order       => 300,
        },
        2 => {
            button      => 1,
            label       => 'Publish',
            # code        =>
            mode        => 'status_contactformgroup',
            class       => 'icon-action',
            return_args => 1,
            order       => 400,
        },
        1 => {
            label       => 'Draft',
            mode        => 'status_contactformgroup',
            return_args => 1,
            order       => 600,
        },
        3 => {
            label       => 'Review',
            mode        => 'status_contactformgroup',
            return_args => 1,
            order       => 700,
        },
        4 => {
            label       => 'Future',
            mode        => 'status_contactformgroup',
            return_args => 1,
            order       => 800,
        },
        5 => {
            label       => 'Ended',
            # code        =>
            mode        => 'status_contactformgroup',
            return_args => 1,
            order       => 900,
        },
    };
    return $actions;
}

sub list_actions_feedback {
    my $actions = {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'feedback' },
            order       => 300,
        },
        unapprove_feedbacks => {
            label       => 'Unapproval',
            mode        => 'unapprove_feedbacks',
            class       => 'icon-action',
            return_args => 1,
            order       => 400,
        },
        approve_feedbacks => {
            label       => 'Approval',
            mode        => 'approve_feedbacks',
            return_args => 1,
            order       => 600,
        },
        addflag2_feedbacks => {
            label       => 'Flagged',
            mode        => 'addflag2_feedbacks',
            return_args => 1,
            order       => 700,
        },
        download_feedbacks => {
            button      => 1,
            label       => 'Download CSV',
            mode        => 'download_feedbacks',
            return_args => 1,
            order       => 800,
        },
    };
    return $actions;
}

sub content_actions {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
    my $uploader = <<MTML;
    </a>
<__trans_section component="ContactForm">
    <a href="javascript:void(0);" class="icon-left icon-action" onclick="return upload_csv()"><__trans phrase="Import from CSV"></a>
        <form method="post" style="display:inline" action="<mt:var name="mt_url">" enctype="multipart/form-data" id="upload_contactform_csv">
        <input type="hidden" name="blog_id" value="0" />
        <input type="hidden" name="__mode" value="upload_contactform_csv" />
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
    my %args;
    my %params = (
                   magic_token => $app->current_magic(),
                   return_args => $app->make_return_args,
                 );
    $uploader = build_tmpl( $app, $uploader, \%args, \%params );
    return {
        'download_contactform_csv' => {
            mode        => 'download_contactform_csv',
            class       => 'icon-download',
            label       => 'Download CSV',
            return_args => 1,
            condition => sub { MT->app->blog ? 0 : 1 },
            order       => 100,
            confirm_msg => sub {
                $plugin->translate( 'Are you sure you want to download all Form Elements?' );
            },
        },
        'upload_contactform_csv' => {
            class       => 'icon-none',
            label       => $uploader,
            condition => sub { MT->app->blog ? 0 : 1 },
            order       => 200,
        },
    };
}

sub name {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->name ) || '...';
    my $edit_link = $app->uri(
        mode => 'view',
        args => {
            _type => $obj->class,
            blog_id => $obj->blog_id,
            id => $obj->id,
        }
    );
    my $icon = status_icon( $prop, $obj, $app );
    # TODO / Check permission
    return qq{
        $icon <a href="$edit_link">$name</a>
    };
}

sub status {
    my ( $prop, $obj, $app ) = @_;
    my $status = $obj->status;
    my $plugin = MT->component( 'ContactForm' );
    my $status_text = $obj->status_text;
    $status_text = $plugin->translate( $status_text );
    my $icon = status_icon( $prop, $obj, $app );
    return $icon . " " . $status_text;
}

sub status_icon {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'ContactForm' );
    my $status = $obj->status;
    my $gif;
    my $alt;
    if ( $status == 1 ) {
        $gif = 'draft.gif';
        $alt = $plugin->translate( 'Draft' );
    } elsif ( $status == 2 ) {
        $gif = 'success.gif';
        $alt = $plugin->translate( 'Publish' );
    } elsif ( $status == 4 ) {
        $gif = 'future.gif';
        $alt = $plugin->translate( 'Future' );
    } elsif ( $status == 3 ) {
        $gif = 'warning.gif';
        $alt = $plugin->translate( 'Review' );
    } elsif ( $status == 5 ) {
        $alt = $plugin->translate( 'Closed' );
        $gif = 'close.gif';
    }
    my $url = MT->static_path . 'images/status_icons/' . $gif;
    my $icon = '<img width="9" height="9" alt="' . $alt . '" src="';
    $icon .= $url . '" />';
    return $icon;
}

sub feedback_status {
    my ( $prop, $obj, $app ) = @_;
    my $status = $obj->status;
    my $status_text = $obj->status_text;
    my $icon = status_icon_feedback( $prop, $obj, $app );
    return $icon . " " . $status_text;
}

sub status_icon_feedback {
    my ( $prop, $obj, $app ) = @_;
    my $status = $obj->status;
    my $gif;
    my $alt = $obj->status_text;
    if ( $status == 1 ) {
        $gif = 'draft.gif';
    } elsif ( $status == 2 ) {
        $gif = 'success.gif';
    } elsif ( $status == 3 ) {
        $gif = 'primary.png';
    }
    my $url = MT->static_path . 'images/status_icons/' . $gif;
    my $icon = '<img width="9" height="9" alt="' . $alt . '" src="';
    $icon .= $url . '" />';
    return $icon;
}

sub feedback_count {
    my ( $prop, $obj, $app ) = @_;
    return $obj->feedback_count;
}

sub type {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'ContactForm' );
    require ContactForm::Plugin;
    if ( my $name = ContactForm::Plugin::__get_registry( $obj->type, 'name' ) ) {
        return $plugin->translate( $name );
    }
    return $app->translate( 'unassigned' );
}

sub required {
    my ( $prop, $obj, $app ) = @_;
    if ( $obj->required ) {
        return '*';
    }
    return '';
}

sub author {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->author->nickname );
}

sub feedback_email {
    my ( $prop, $obj, $app ) = @_;
    return MT->config->FeedbackEmailLink
                ? '<a href="mailto:' . $obj->email . '">' . $obj->email . '</a>'
                : $obj->email;
}

1;
