# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::CMS;

use strict;
use MT::Util qw( encode_html make_string_csv encode_url );

# This package simply holds code that is being grafted onto the CMS
# application; the namespace of the package is different, but the 'app'
# variable is going to be a MT::App::CMS object.

sub CMSSaveFilter_group {
    my ( $eh, $app ) = @_;

    require MT::Group;
    my $status = $app->param('status');
    return 1 if $status == MT::Group::INACTIVE();

    my $name = $app->param('name');
    if ( defined $name ) {
        $name =~ s/(^\s+|\s+$)//g;
        $app->param( 'name', $name );
    }
    return $app->error( $app->translate("Each group must have a name.") )
        if ( !$name );
    1;
}

sub CMSViewPermissionFilter_group {
    my ( $eh, $app, $id ) = @_;
    return $id && ( $app->user->is_superuser() );
}

# TBD: group management capability
sub CMSSavePermissionFilter_group {
    my ( $eh, $app, $id ) = @_;
    return $app->user->is_superuser;
}

# TBD: group management capability
sub CMSDeletePermissionFilter_group {
    my ( $eh, $app, $obj ) = @_;
    return $app->user->is_superuser();
}

sub dialog_select_group_user {
    my $app = shift;
    return $app->permission_denied()
        unless $app->user->is_superuser;

    my $type = $app->param('_type');

    my $hasher = sub {
        my ( $obj, $row ) = @_;
        if ( UNIVERSAL::isa( $obj, 'MT::Author' ) ) {
            $row->{label}       = $row->{name};
            $row->{description} = $row->{nickname};
        }
        elsif ( UNIVERSAL::isa( $obj, 'MT::Group' ) ) {
            $row->{label}       = $row->{name};
            $row->{description} = $row->{description};
        }
    };

    if ( $app->param('search') || $app->param('json') ) {
        my $params = {
            panel_type   => $type,
            list_noncron => 1,
            panel_multi  => 1,
        };

        my $terms = {};
        if ( $type && ( $type eq 'author' ) ) {
            require MT::Author;
            $terms->{status} = MT::Author::ACTIVE();
            $terms->{type}   = MT::Author::AUTHOR();
        }
        else {
            require MT::Group;
            $terms->{status} = MT::Group::ACTIVE();
        }

        $app->listing(
            {   terms    => $terms,
                args     => { sort => 'name' },
                type     => $type,
                code     => $hasher,
                params   => $params,
                template => 'include/listing_panel.tmpl',
                $app->param('search') ? ( no_limit => 1 ) : (),
            }
        );
    }
    else {
        my @panels     = qw{ author group };
        my $panel_info = {
            'author' => {
                panel_title       => $app->translate("Select Users"),
                panel_label       => $app->translate("Username"),
                items_prompt      => $app->translate("Users Selected"),
                search_label      => $app->translate("Search Users"),
                panel_description => $app->translate("Name"),
            },
            'group' => {
                panel_title       => $app->translate("Select Groups"),
                panel_label       => $app->translate("Group Name"),
                items_prompt      => $app->translate("Groups Selected"),
                search_label      => $app->translate("Search Groups"),
                panel_description => $app->translate("Description"),
            },
        };
        my $params;
        $params->{panel_multi}  = 1;
        $params->{dialog_title} = $app->translate("Add Users to Groups");
        $params->{panel_loop}   = [];

        for ( my $i = 0; $i <= $#panels; $i++ ) {
            my $source       = $panels[$i];
            my $panel_params = {
                panel_type => $source,
                %{ $panel_info->{$source} },
                list_noncron     => 1,
                panel_last       => $i == $#panels,
                panel_first      => $i == 0,
                panel_number     => $i + 1,
                panel_total      => $#panels + 1,
                panel_has_steps  => ( $#panels == '0' ? 0 : 1 ),
                panel_searchable => 1,
            };

            # Only show active user/groups.
            my $limit = $app->param('limit') || 25;
            my $terms = {};
            my $args  = {
                sort  => 'name',
                limit => $limit,
            };

            if ( $source eq 'author' ) {
                require MT::Author;
                $terms->{status} = MT::Author::ACTIVE();
                $terms->{type}   = MT::Author::AUTHOR();
            }
            else {
                require MT::Group;
                $terms->{status} = MT::Group::ACTIVE();
            }

            $app->listing(
                {   no_html => 1,
                    code    => $hasher,
                    type    => $source,
                    params  => $panel_params,
                    terms   => $terms,
                    args    => $args,
                }
            );
            if (!$panel_params->{object_loop}
                || ( $panel_params->{object_loop}
                    && @{ $panel_params->{object_loop} } < 1 )
                )
            {
                $params->{"missing_$source"} = 1;
                $params->{"missing_data"}    = 1;
            }
            push @{ $params->{panel_loop} }, $panel_params;
        }

        # save the arguments from whence we came...
        $params->{return_args} = $app->return_args;

        if ( $app->param('confirm_js') ) {
            $params->{confirm_js} = $app->param('confirm_js');
            $params->{confirm_js} =~ s/\W//g;
        }

        $app->load_tmpl( 'dialog/dialog_select_group_user.tmpl', $params );
    }
}

sub dialog_select_user {
    my $app = shift;
    return $app->permission_denied()
        unless $app->user->is_superuser;

    my $id = $app->param('group_id');

    my $hasher = sub {
        my ( $obj, $row ) = @_;
        $row->{label}       = $row->{name};
        $row->{description} = $row->{nickname};
    };

    my $grp_class = $app->model("group") or return;
    require MT::Group;
    my $group = MT::Group->load($id)
        or return $app->error( $app->translate("Invalid group") );

    return $app->listing(
        {   type  => 'author',
            terms => {
                type   => MT::Author::AUTHOR(),
                status => MT::Author::ACTIVE(),
            },
            args     => { sort => 'name' },
            template => 'dialog/select_users.tmpl',
            code     => $hasher,
            params   => {
                dialog_title => $app->translate(
                    "Add Users to Group [_1]", $group->name
                ),
                panel_type        => 'author',
                panel_title       => $app->translate("Select Users"),
                panel_label       => $app->translate("Username"),
                panel_description => $app->translate("Name"),
                items_prompt      => $app->translate("Users Selected"),
                search_prompt     => $app->translate(
                    "Type a username to filter the choices below."),
                panel_multi      => 1,
                panel_last       => 1,
                panel_first      => 1,
                panel_searchable => 1,
                list_noncron     => 1,
                group_name       => $group->name,
                group_id         => $group->id
            },
        }
    );
}

sub remove_member {
    my $app      = shift;
    my $q        = $app->param;
    my $user     = $app->user;
    my $group_id = $q->param('group_id');
    my @id       = $app->param('id');

    $app->validate_magic or return;
    $user->is_superuser  or return $app->permission_denied();

    $app->setup_filtered_ids
        if $app->param('all_selected');

    my $cls = MT->model('association');
    foreach my $id (@id) {
        my $assoc = $cls->load($id)
            or
            return $app->error( $app->translate( "Load failed: [_1]", $id ) );
        my $group  = $assoc->group;
        my $member = $assoc->user;
        $group->remove_user($member);

        $app->log(
            {   message => $app->translate(
                    "User '[_1]' (ID:[_2]) removed from group '[_3]' (ID:[_4]) by '[_5]'",
                    $member->name, $member->id, $group->name,
                    $group->id,    $user->name
                ),
                level    => MT::Log::INFO(),
                class    => 'system',
                category => 'remove_group_member'
            }
        );
    }

    $app->add_return_arg( saved_removed => 1 );
    $app->call_return;
}

sub add_member {
    my $app  = shift;
    my $q    = $app->param;
    my $user = $app->user;

    $app->validate_magic or return;
    $user->is_superuser  or return $app->permission_denied();

    my $groups = $q->param('group');
    my $users  = $q->param('author');

    my @groups = split( /\,/, $groups );
    my @users  = split( /\,/, $users );
    my $grp_class = $app->model('group');
    my $usr_class = $app->model('author');

    foreach my $grp (@groups) {
        my $gid = $grp;
        $gid =~ s/\D//g;
        my $group = $grp_class->load($gid)
            or return $app->error(
            $app->translate( "Group load failed: [_1]", $gid ) );

        foreach my $usr (@users) {
            my $uid = $usr;
            $uid =~ s/\D//g;
            my $member = $usr_class->load($uid)
                or return $app->error(
                $app->translate( "User load failed: [_1]", $uid ) );

            $group->add_user($member);
            $app->log(
                {   message => $app->translate(
                        "User '[_1]' (ID:[_2]) was added to group '[_3]' (ID:[_4]) by '[_5]'",
                        $member->name, $member->id, $group->name,
                        $group->id,    $user->name
                    ),
                    level    => MT::Log::INFO(),
                    class    => 'system',
                    category => 'add_group_member'
                }
            );
        }

    }

    my $uri = $app->uri(
        mode => 'list',
        args => { '_type' => 'group_member', saved => 1, blog_id => 0 }
    );
    $app->redirect($uri);
}

sub delete_group {
    my $app = shift;

    # To avoid infinite loop
    local *MT::App::CMS::handlers_for_mode = sub {undef};
    return $app->delete(@_);
}

sub view_group {
    my $app = shift;

    return $app->return_to_dashboard( redirect => 1 )
        if $app->param('blog_id');

    return $app->permission_denied()
        unless $app->user->is_superuser;

    my ($params) = @_;
    my $id = $app->param('id');
    my %param;
    %param = (%$params) if defined $params;
    my $group_class = $app->model('group');
    my $cfg         = $app->config;

    return $app->errtrans('Invalid request')
        if $cfg->AuthenticationModule ne 'MT'
            && $cfg->ExternalGroupManagement
            && !$id;

    my $obj = $group_class->load($id) if $id;
    my $user_class = $app->model('user');
    if ($id) {
        %param = %{ $obj->column_values };
        delete $param{external_id};
        $app->add_breadcrumb(
            $app->translate("Users & Groups"),
            $app->uri( mode => 'list_group' )
        );
        $app->add_breadcrumb( $app->translate("Group Profile") );
        $param{nav_authors} = 1;
        $param{status_enabled} = 1 if $obj->is_active;
        if ( $cfg->AuthenticationModule ne 'MT' ) {
            if ( $cfg->ExternalGroupManagement ) {
                my $id = $obj->external_id;
                $id = '' unless defined $id;
                if ( length($id) && ( $id !~ m/[\x00-\x1f\x80-\xff]/ ) ) {
                    $param{show_external_id} = 1;
                    $param{external_id}      = $id;
                }
            }
        }

        if ( my $created_by = $user_class->load( $obj->created_by ) ) {
            $param{created_by} = $created_by->name;
        }
        else {
            $param{created_by} = '';
        }
        $param{user_count}       = $obj->user_count;
        $param{permission_count} = MT->model('association')->count(
            {   group_id => $id,
                type     => MT::Association::GROUP_BLOG_ROLE(),
            }
        );
        if ( $app->user->is_superuser ) {
            if ( !$app->config->ExternalGroupManagement ) {
                $param{can_edit_groupname} = 1;
            }
        }
    }
    else {
        $app->add_breadcrumb(
            $app->translate("Users & Groups"),
            $app->uri( mode => 'list_group' )
        );
        $app->add_breadcrumb( $app->translate("Group Profile") );
        $param{nav_authors}    = 1;
        $param{new_object}     = 1;
        $param{status_enabled} = 1;
        if ( $app->user->is_superuser ) {
            $param{can_edit_groupname} = 1;
        }
        if ( $cfg->AuthenticationModule ne 'MT' ) {
            if ( $cfg->ExternalGroupManagement ) {
                my $id = $obj->external_id;
                $id = '' unless defined $id;
                if ( length($id) && ( $id !~ m/[\x00-\x1f\x80-\xff]/ ) ) {
                    $param{show_external_id} = 1;
                    $param{external_id}      = $id;
                }
            }
        }
    }
    $param{group_support}       = 1;
    $param{search_label}        = $app->translate('Groups');
    $param{object_type}         = 'group';
    $param{object_label}        = MT::Group->class_label;
    $param{object_label_plural} = MT::Group->class_label_plural;
    $param{screen_class}        = "edit-group";
    $param{saved}               = $app->param('saved');
    $param{error}               = $app->errstr if $app->errstr;
    my $tmpl = $app->load_tmpl("edit_group.tmpl");
    $tmpl->param( \%param );
    return $tmpl;
}

sub build_group_table {
    my $app = shift;
    my (%args) = @_;

    my $i = 1;
    my @group;
    my $iter;
    if ( $args{load_args} ) {
        my $class = $app->model('group');
        $iter = $class->load_iter( @{ $args{load_args} } );
    }
    elsif ( $args{iter} ) {
        $iter = $args{iter};
    }
    elsif ( $args{items} ) {
        $iter = sub { pop @{ $args{items} } };
    }
    return [] unless $iter;
    my $param = $args{param};
    $param->{has_edit_access}  = $app->user->is_superuser();
    $param->{is_administrator} = $app->user->is_superuser();
    my ( %blogs, %user_count_refs );
    while ( my $group = $iter->() ) {
        my $row = {
            name           => $group->name,
            description    => $group->description,
            display_name   => $group->display_name,
            status_enabled => $group->is_active,
            id             => $group->id,
            user_count     => 0
        };
        $user_count_refs{ $group->id } = \$row->{user_count};
        $row->{object} = $group;
        push @group, $row;
    }
    return [] unless @group;
    my $assoc_class       = $app->model('association');
    my $author_count_iter = $assoc_class->count_group_by(
        {   type     => MT::Association::USER_GROUP(),
            group_id => [ keys %user_count_refs ],
        },
        { group => ['group_id'], }
    );
    while ( my ( $count, $author_id ) = $author_count_iter->() ) {
        ${ $user_count_refs{$author_id} } = $count;
    }
    $param->{group_table}[0]{object_loop} = \@group;

    $app->load_list_actions( 'group', $param );
    $param->{object_loop} = $param->{group_table}[0]{object_loop};

    \@group;
}

# Handler for removing a member from a group, doesn't remove a group
sub remove_group {
    my $app       = shift;
    my $q         = $app->param;
    my $user      = $app->user;
    my $author_id = $q->param('author_id');
    my @id        = $app->param('id');

    $app->validate_magic or return;
    $user->is_superuser  or return $app->permission_denied();

    my $grp_class    = $app->model('group');
    my $author_class = $app->model('author');
    my $author       = $author_class->load($author_id)
        or return $app->error(
        $app->translate( "User load failed: [_1]", $author_id ) );

    foreach (@id) {
        my $group_id = $_;
        my $group    = $grp_class->load($group_id)
            or return $app->error(
            $app->translate( "Group load failed: [_1]", $group_id ) );
        $author->remove_group($group);
        $app->log(
            {   message => $app->translate(
                    "User '[_1]' (ID:[_2]) removed from group '[_3]' (ID:[_4]) by '[_5]'",
                    $author->name, $author->id, $group->name,
                    $group->id,    $user->name
                ),
                level    => MT::Log::INFO(),
                class    => 'system',
                category => 'remove_group_member'
            }
        );
    }

    $app->add_return_arg( saved_removed => 1 );
    $app->call_return;
}

# Handler for adding a user to a group
sub add_group {
    my $app  = shift;
    my $q    = $app->param;
    my $user = $app->user;

    $app->validate_magic or return;
    $user->is_superuser  or return $app->permission_denied();

    my $author_id    = $q->param('author_id');
    my $ids          = $app->param('ids');
    my $author_class = $app->model('author');
    my $author       = $author_class->load($author_id)
        or return $app->error(
        $app->translate( "Author load failed: [_1]", $author_id ) );

    if ($ids) {
        my @id = split( /\,/, $ids );
        my $grp_class = $app->model('group');
        foreach (@id) {
            my $group_id = $_;
            if ($group_id) {
                my $group = $grp_class->load($group_id)
                    or return $app->error(
                    $app->translate( "Group load failed: [_1]", $group_id ) );
                $group->add_user($author);
                $app->log(
                    {   message => $app->translate(
                            "User '[_1]' (ID:[_2]) was added to group '[_3]' (ID:[_4]) by '[_5]'",
                            $author->name, $author->id, $author->name,
                            $group->id,    $user->name
                        ),
                        level    => MT::Log::INFO(),
                        class    => 'system',
                        category => 'add_group_member'
                    }
                );
            }
        }
    }

    my $uri = $app->uri(
        mode => 'list_group',
        args => { author_id => $author_id, saved => 1 }
    );
    $app->redirect($uri);
}

sub dialog_select_group {
    my $app = shift;
    return $app->permission_denied()
        unless $app->user->is_superuser;

    my $id = $app->param('author_id');
    require MT::Author;
    require MT::Group;
    my $author = MT::Author->load($id)
        or return $app->error( $app->translate("Invalid user") );

    my $hasher = sub {
        my ( $obj, $row ) = @_;
        $row->{label} = $row->{display_name} || $row->{name};
    };

    if ( $app->param('search') || $app->param('json') ) {
        my $params = {
            panel_type   => 'group',
            list_noncron => 1,
            panel_multi  => 1,
        };
        $app->listing(
            {   terms  => { status => MT::Group::ACTIVE() },
                type   => 'group',
                code   => $hasher,
                params => $params,
                template => 'include/listing_panel.tmpl',
                $app->param('search') ? () : (
                    pre_build => sub {
                        my ($param) = @_;
                    }
                ),
            }
        );
    }
    else {
        my $params = {
            dialog_title => $app->translate(
                "Assign User [_1] to Groups", $author->name
            ),
            panel_type        => 'group',
            panel_title       => $app->translate("Select Groups"),
            panel_label       => $app->translate("Group"),
            panel_description => $app->translate("Description"),
            items_prompt      => $app->translate("Groups Selected"),
            search_prompt     => $app->translate(
                "Type a group name to filter the choices below."),
            panel_multi      => 1,
            panel_last       => 1,
            panel_first      => 1,
            panel_searchable => 1,
            list_noncron     => 1,
            edit_author_name => $author->name,
            edit_author_id   => $author->id
        };

        $app->listing(
            {   type    => 'group',
                no_html => 1,
                code    => $hasher,
                terms   => { status => MT::Group::ACTIVE() },
                args    => { sort => 'name' },
                params  => $params,
            }
        );
        if ( !$params->{object_loop}
            || ( $params->{object_loop} && @{ $params->{object_loop} } < 1 ) )
        {
            $params->{"missing_group"} = 1;
            $params->{"missing_data"}  = 1;
        }
        $app->load_tmpl( 'dialog/select_groups.tmpl', $params );
    }
}

sub dialog_grant_role {
    my $app = shift;

    my $tmpl = $app->response_content;
    return unless $tmpl;
    my $params    = $tmpl->param;
    my $group_id  = $app->param('group_id');
    my $author_id = $app->param('author_id');
    my $type      = $app->param('_type');
    if ($author_id) {
        return $tmpl;
    }
    elsif ($group_id) {
        $params->{group_id} = $group_id;
        return $tmpl;
    }
    elsif ( $type eq 'user' ) {
        return $tmpl;
    }
    my $grp;
    my $grp_class = $app->model("group");
    if ($group_id) {
        return $tmpl unless $grp_class;
        $grp = $grp_class->load($group_id);
        if ($grp) {
            $params->{group_name} = $grp->name;
            $params->{group_id}   = $grp->id;
        }
    }
    my $hasher = sub {
        my ( $obj, $row ) = @_;
        $row->{label} = $row->{name};
        $row->{description} = $row->{nickname} if exists $row->{nickname};
    };
    my $panel_count    = scalar( @{ $params->{panel_loop} } );
    my $listing_params = {
        panel_type        => 'group',
        panel_title       => $app->translate("Select Groups"),
        panel_label       => $app->translate("Group Name"),
        items_prompt      => $app->translate("Groups Selected"),
        search_label      => $app->translate("Search Groups"),
        panel_description => $app->translate("Description"),
        list_noncron      => 1,
        panel_last        => $panel_count == 0,
        panel_first     => 1,                              # Group comes first
        panel_number    => 1,
        panel_total     => $panel_count + 1,
        panel_has_steps => ( $panel_count == '0' ? 0 : 1 ),
        panel_searchable => 1,
    };
    $app->listing(
        {   no_html => 1,
            code    => $hasher,
            type    => 'group',
            params  => $listing_params,
            terms   => { status => $grp_class->ACTIVE() },
            args    => { sort => 'name' },
        }
    );

    if (!$listing_params->{object_loop}
        || ( $listing_params->{object_loop}
            && @{ $listing_params->{object_loop} } < 1 )
        )
    {
        $params->{"missing_group"} = 1;
        $params->{"missing_data"}  = 1;
    }

    for my $panel ( @{ $params->{panel_loop} } ) {
        $panel->{panel_first}     = 0;
        $panel->{panel_number}    = $panel->{panel_number} + 1;
        $panel->{panel_total}     = $panel_count + 1;
        $panel->{panel_has_steps} = 1;
    }
    unshift @{ $params->{panel_loop} }, $listing_params;
    $tmpl;
}

## Bulk Author Management

sub author_bulk {
    my $app    = shift;
    my $author = $app->user;
    return unless $app->validate_magic;
    unless ( $author->is_superuser ) {
        return $app->permission_denied();
    }
    if ( $app->config->ExternalUserManagement ) {
        return $app->error(
            $app->translate(
                "Bulk import cannot be used under external user management.")
        );
    }
    my %param = $_[0] ? %{ $_[0] } : ();
    my $q = $app->param;
    $param{search_label}   = $app->translate('Users');
    $param{object_type}    = 'author';
    $param{encoding_names} = MT::I18N::const('ENCODING_NAMES');
    my $new_user_blog_parent = $param{new_user_default_website_id}
        = $app->config('NewUserDefaultWebsiteId') || '';
    if ($new_user_blog_parent) {
        my $site = MT->model('website')->load($new_user_blog_parent);
        if ($site) {
            $param{new_user_default_website_name} = $site->name;
        }
    }
    $app->add_breadcrumb(
        $app->translate("Users & Groups"),
        $app->uri( 'mode' => 'list_author' )
    );
    $app->add_breadcrumb( $app->translate('Bulk management') );
    $app->build_page( 'author_bulk.tmpl', \%param );
}

sub upload_author_bulk {
    my $app = shift;

    $app->validate_magic() or return;
    if ( !$app->user->is_superuser ) {
        return $app->permission_denied();
    }
    if ( $app->config->ExternalUserManagement ) {
        return $app->error(
            $app->translate(
                "Bulk import cannot be used under external user management.")
        );
    }

    my $q = $app->param;
    my ( $fh, $no_upload );
    if ( $ENV{MOD_PERL} ) {
        my $up = $q->upload('file');
        $no_upload = !$up || !$up->size;
        $fh = $up->fh if $up;
    }
    else {
        ## Older versions of CGI.pm didn't have an 'upload' method.
        eval { $fh = $q->upload('file') };
        if ( $@ && $@ =~ /^Undefined subroutine/ ) {
            $fh = $q->param('file');
        }
        $no_upload = !$fh;
    }

    return $app->error( $app->translate("Please select a file to upload.") )
        if $no_upload;

    my $encoding = $q->param('encoding') || 'guess';
    my $guess = $encoding eq 'guess' ? 1 : 0;
    $app->{no_print_body} = 1;

    local $| = 1;
    my $charset = $app->charset;
    $app->send_http_header(
        'text/html' . ( $charset ? "; charset=$charset" : '' ) );

    my $param;
    $param = {};
    $app->print_encode(
        $app->build_page( 'create_author_bulk_start.tmpl', $param ) );

    require MT::Enterprise::BulkCreation;
    require MT::Util;

    binmode $fh;
    my ( $bytes, $csv_data ) = (0);
    my $i       = 0;
    my $header  = 0;
    my $error   = 0;
    my %numbers = ( 'register' => 0, 'update' => 0, 'delete' => 0 );
    if ( 'guess' eq $encoding || 'utf8' eq $encoding ) {

        # UTF-8 BOM must be removed before processing.
        my $bom;
        read $fh, $bom, 3;
        if ( $bom !~ /^\x{EF}\x{BB}\x{BF}$/ ) {
            seek( $fh, 0, 0 )
                or return $app->error( $app->translate("Can't rewind") );
        }
    }
    while ( !eof($fh) ) {
        ++$i;
        my $line = <$fh>;
        $line .= <$fh> while ( $line =~ tr/"// % 2 and !eof($fh) );    ##"
        $encoding = MT::I18N::guess_encoding($line)
            if $guess;
        my @line_item;
        eval {
            $line = Encode::decode( $encoding, $line );
            $line =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
            @line_item
                = map { /^"(.*)"$/s ? scalar( $_ = $1, s/""/"/g, $_ ) : $_ }
                ( $line =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g );          ##"
        };

        # ignore header line if it is 'command'; straight from an export
        if ( ( $i == 1 ) && ( $line_item[0] eq 'command' ) ) {
            $header = 1;
            next;
        }
        my $result = MT::Enterprise::BulkCreation->do_bulk_create(
            LineNumber => $i + $header,
            Line       => \@line_item,
            Callback =>
                sub { $app->print_encode( '<li>' . $_[0] . '</li>' ); },
            App => $app,
        );
        if ($result) {
            $numbers{ lc( $line_item[0] ) }++;
        }
        else {
            $app->print_encode(
                '<li>' . MT::Enterprise::BulkCreation->errstr . '</li>' );
            $error = 1;
        }
    }
    close $fh;

    if ( $header && ( 1 == $i ) ) {
        $app->print_encode(
            '<li>'
                . $app->translate(
                'No records were found in the file.  Make sure the file uses CRLF as the line-ending characters.'
                )
                . '</li>'
        );
        $error = 1;
    }
    $param->{create_success} = !$error;
    $param->{message}
        = $app->translate(
        'Registered [quant,_1,user,users], updated [quant,_2,user,users], deleted [quant,_3,user,users].',
        $numbers{'register'}, $numbers{'update'}, $numbers{'delete'} );

    $app->print_encode(
        $app->build_page( 'create_author_bulk_end.tmpl', $param ) );

    1;
}

sub export_authors {
    my $app    = shift;
    my $author = $app->user;
    my $perms  = $app->permissions;

    if ( !$app->user->is_superuser ) {
        return $app->permission_denied();
    }
    if ( $app->config->ExternalUserManagement ) {
        return $app->error(
            $app->translate(
                "Bulk author export cannot be used under external user management."
            )
        );
    }

    $app->validate_magic() or return;
    $| = 1;
    my $enc = $app->config('ExportEncoding');
    $enc = ( $app->charset || '' ) if ( !$enc );

    my $q           = $app->param;
    my $filter_args = $q->param('filter_args');
    my %terms;
    $q->parse_params($filter_args) if $filter_args;
    if (   ( my $filter_col = $app->param('filter') )
        && ( my $val = $app->param('filter_val') ) )
    {
        if ( !exists( $terms{$filter_col} ) ) {
            $terms{$filter_col} = $val;
        }
    }
    $terms{'type'} = MT::Author::AUTHOR();
    require MT::Author;
    my $iter = MT::Author->load_iter( \%terms,
        { 'sort' => 'created_on', 'direction' => 'ascend' } );

    my @ts = gmtime(time);
    my $ts = sprintf "%04d-%02d-%02d-%02d-%02d-%02d", $ts[5] + 1900,
        $ts[4] + 1,
        @ts[ 3, 2, 1, 0 ];
    my $file = "authors_$ts.csv";
    $app->{no_print_body} = 1;
    $app->set_header( "Content-Disposition" => "attachment; filename=$file" );
    $app->send_http_header(
        $enc
        ? "text/csv; charset=$enc"
        : 'text/csv'
    );

    my $csv = "command,user name,new user name,display name,email,language\n";
    while ( my $author = $iter->() ) {

       # columns:
       # Command, Username, NewUsername, Display Name, Email Address, Language
        my @col;
        push @col, 'update';
        push @col, make_string_csv( $author->name, $enc ) if $enc;
        push @col, make_string_csv( $author->name, $enc ) if $enc;
        push @col, make_string_csv( $author->nickname, $enc ) if $enc;
        push @col, $author->email;
        push @col, $author->preferred_language;
        $csv .= ( join ',', @col ) . "\n";
        $app->print( Encode::encode( $enc, $csv ) );
        $csv = '';
    }
}

sub synchronize {
    my $app = shift;
    $app->validate_magic or return;
    $app->user->is_superuser
        or return $app->permission_denied();
    my ($type) = $app->param('_type');

    my $method = "synchronize_$type";
    require MT::Auth;
    my $count = MT::Auth->$method;
    my $args  = ();
    if ( defined $count ) {
        $args->{synchronized} = 1 if $count >= 0;
    }
    else {
        $args->{error} = 1;
    }

    $args->{_type}   = $type;
    $args->{blog_id} = 0;
    $app->redirect(
        $app->uri(
            'mode' => "list",
            args   => $args
        )
    );
}

sub grant_role {
    my $app = shift;

    my $user = $app->user;
    return unless $app->validate_magic;

    my $blogs  = $app->param('blog')  || $app->param('website') || '';
    my $groups = $app->param('group') || '';
    my $roles  = $app->param('role')  || '';
    my $blog_id  = $app->param('blog_id');
    my $group_id = $app->param('group_id');
    my $role_id  = $app->param('role_id');

    my @blogs    = split /,/, $blogs;
    my @groups   = split /,/, $groups;
    my @role_ids = split /,/, $roles;

    require MT::Blog;
    require MT::Role;
    my $grp_class = $app->model("group");

    push @blogs, $blog_id if $blog_id;
    foreach (@blogs) {
        my $id = $_;
        $id =~ s/\D//g;
        $_ = MT::Blog->load($id);
    }
    @blogs = grep { ref $_ } @blogs;

    push @groups, $group_id if $group_id;
    foreach (@groups) {
        return unless $grp_class;
        my $id = $_;
        $id =~ s/\D//g;
        $_ = $grp_class->load($id);
    }
    @groups = grep { ref $_ } @groups;
    $app->error(undef);

    my @can_grant_administer = map 1, 1 .. @blogs;
    if ( !$user->is_superuser ) {
        for ( my $i = 0; $i < scalar(@blogs); $i++ ) {
            my $perm = $user->permissions( $blogs[$i] );
            if ( !$perm->can_do('grant_administer_role') ) {
                $can_grant_administer[$i] = 0;
                if ( !$perm->can_do('grant_role_for_blog') ) {
                    return $app->permission_denied();
                }
            }
        }
    }

    push @role_ids, $role_id if $role_id;
    my @roles = grep { defined $_ }
        map { MT::Role->load($_) }
        map { my $id = $_; $id =~ s/\D//g; $id } @role_ids;

    require MT::Association;

    # TBD: handle case for associating system roles to users/groups
    foreach my $blog (@blogs) {
        my $can_grant_administer = shift @can_grant_administer;
        foreach my $role (@roles) {
            next
                if ( ( !$can_grant_administer )
                && ( $role->has('administer_blog') ) );
            foreach my $ug (@groups) {
                MT::Association->link( $ug => $role => $blog );
            }
        }
    }

    $app->add_return_arg( saved => 1 );
    $app->call_return;

}

sub edit_role {
    my $app         = shift;
    my $role_id     = $app->param('id');
    my $tmpl        = $app->response_content or return;
    my $params      = $tmpl->param;
    my $assoc_class = $app->model('association');
    my $group_count = $assoc_class->count(
        {   role_id  => $role_id,
            group_id => [ 1, undef ],
        },
        {   unique     => 'group_id',
            range_incl => { group_id => 1 },
        }
    );
    $params->{members} += $group_count;
    $tmpl;
}

sub CMSPreSave_author {
    my ( $eh, $app, $obj, $original ) = @_;

    if ( $app->config->ExternalUserManagement ) {
        if ( 'save_profile' eq $app->mode ) {
            if ( $obj->is_active ) {
                require MT::Auth;
                my $error = MT::Auth->sanity_check($app);
                return $eh->error($error)
                    if ( defined $error ) && ( $error ne '' );
            }
        }
        elsif ( $original->id && ( $original->name ne $obj->name ) ) {
            return $eh->error(
                $app->translate(
                    "A user can't change his/her own username in this environment."
                )
            );
        }

        if ( $obj->id ) {
            if ( $original->status != $obj->status ) {
                if ( $obj->status == MT::Author::ACTIVE() ) {

                    # trying to reactivate an author...
                    MT::Auth->synchronize_author( User => $obj );
                    if ( $obj->status != MT::Author::ACTIVE() ) {

                        # status was reverted for whatever reason...
                        return $eh->error(
                            $app->translate(
                                "An error occurred when enabling this user.")
                        );
                    }
                }
            }
        }
    }
    1;
}

sub edit_author {
    my ( $eh, $app, $param, $tmpl ) = @_;
    return unless UNIVERSAL::isa( $tmpl, 'MT::Template' );
    my $q           = $app->param;
    my $type        = $q->param('_type');
    my $class       = $app->model($type) or return;
    my $id          = $q->param('id');
    my $author      = $app->user;
    my $obj_promise = MT::Promise::delay(
        sub {
            return $class->load($id) || undef;
        }
    );
    my $obj;
    if ($id) {
        $obj = $obj_promise->force()
            or return $app->error(
            $app->translate(
                "Load failed: [_1]",
                $class->errstr || $app->translate("(no reason given)")
            )
            );
        if ( $type eq 'author' ) {
            require MT::Auth;
            if ( $app->user->is_superuser ) {
                if ( $app->config->ExternalUserManagement ) {
                    if ( MT::Auth->synchronize_author( User => $obj ) ) {
                        $obj = $class->load($id);
                        ## we only sync name and status here
                        $param->{name}   = $obj->name;
                        $param->{status} = $obj->status;
                        if ( ( $id == $author->id ) && ( !$obj->is_active ) )
                        {
                            ## superuser has been attempted to disable herself - something bad
                            $obj->status( MT::Author::ACTIVE() );
                            $obj->save;
                            $param->{superuser_attempted_disabled} = 1;
                        }
                    }
                    my $id = $obj->external_id;
                    $id = '' unless defined $id;
                    if ( length($id) && ( $id !~ m/[\x00-\x1f\x80-\xff]/ ) ) {
                        $param->{show_external_id} = 1;
                    }
                }
                delete $param->{can_edit_username};
            }
            else {
                if ( !$app->config->ExternalUserManagement ) {
                    $param->{can_edit_username} = 1;
                }
            }
            $param->{group_count} = $obj->group_count;
        }
    }
    else {    # object is new
        if ( $type eq 'author' ) {
            if ( !$app->config->ExternalUserManagement ) {
                if ( $app->config->AuthenticationModule ne 'MT' ) {
                    $param->{new_user_external_auth} = '1';
                }
            }
        }
    }
    if ( $type eq 'author' ) {
        $param->{'external_user_management'}
            = $app->config->ExternalUserManagement;
    }
    my $element = $tmpl->getElementById('system_msg');
    if ($element) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
<mt:if name="superuser_attempted_disabled">
    <mtapp:statusmsg
        id="superuser-atempted-disabled"
        class="alert">
        <__trans_section component="enterprise"><__trans phrase="Movable Type Advanced has just attempted to disable your account during synchronization with the external directory. Some of the external user management settings must be wrong. Please correct your configuration before proceeding."></__trans_section>
    </mtapp:statusmsg>
</mt:if>
EOT
        $element->innerHTML( $text . $contents );
    }
    $tmpl;
}

sub cfg_registration {
    my ( $eh, $app, $param, $tmpl ) = @_;
    return unless UNIVERSAL::isa( $tmpl, 'MT::Template' );
    $param->{external_user_management}
        = $app->config->ExternalUserManagement ? 1 : 0;
    1;
}

sub cfg_archives {
    my ( $eh, $app, $param, $tmpl ) = @_;
    return unless UNIVERSAL::isa( $tmpl, 'MT::Template' );
    if ( $app->config->ObjectDriver =~ qr/(db[id]::)?u(ms)?sqlserver/i ) {
        $param->{hide_build_option} = 1;
    }
    1;
}

sub _inject_styles {
    my ($tmpl) = @_;

    my $elements = $tmpl->getElementsByTagName('setvarblock');
    my ($element)
        = grep { 'html_head' eq $_->getAttribute('name') } @$elements;
    if ($element) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
    <style type="text/css" media="screen">
        #zero-state {
            margin-left: 0;
        }
        #list-author .page-desc {
            display: none;
        }
        .system .content-nav .msg {
            margin-left: 160px;
        }
    </style>
EOT
        $element->innerHTML( $text . $contents );
    }
    1;
}

1;
