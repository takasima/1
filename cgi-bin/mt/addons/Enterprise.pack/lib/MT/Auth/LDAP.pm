# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Auth::LDAP;

use strict;
use base 'MT::Auth::MT';
use MT::Author qw ( AUTHOR ACTIVE );
use MT::Group;
use MT::LDAP;

sub init {
    my $auth = shift;
    return MT::Auth::LDAP->error( $auth->errstr ) unless $auth->ldap;
    $auth;
}

sub DESTROY {
    my $auth = shift;
    $auth->{ldap} && $auth->{ldap}->unbind_ldap;
}

sub new_user {
    my $auth = shift;
    my ( $app, $user ) = @_;
    my $p = $app->request('ldap_user_profile') || {};
    my $ext_id = delete $p->{external_id};
    $user->set_values($p);
    $user->external_id($ext_id) if defined $ext_id;
    my $tag_delim = $app->config->DefaultUserTagDelimiter;
    $user->entry_prefs( 'tag_delim' => $tag_delim );
    $user->created_on(0) if $app->config->ExternalUserManagement;
    my $result = $user->save;

    if ($result) {
        $user->add_default_roles;
        if ( $app->config->ExternalGroupManagement ) {
            $auth->synchronize_group_user( User => $user );
        }
    }
    $result;
}

sub new_login {
    my $auth = shift;
    my ( $app, $user ) = @_;
    if (   $user
        && ( $user->is_active )
        && ( $app->config->ExternalGroupManagement ) )
    {
        $auth->synchronize_group_user( User => $user );
    }
}

sub sanity_check {
    my $auth      = shift;
    my ($app)     = @_;
    my $q         = $app->param;
    my $id        = $q->param('id');
    my $author_id = $q->param('author_id');
    my $cfg       = $app->config;
    my $ldap      = $auth->ldap;
    my $cmpnt     = MT->component('enterprise');

    # get entry
    my $attr_email    = $cfg->LDAPUserEmailAttribute    || 'mail';
    my $attr_fullname = $cfg->LDAPUserFullNameAttribute || 'cn';
    my $attr_uid      = $ldap->{uid_attr_name};
    my $attrs
        = [ $attr_email, $attr_fullname, $attr_uid, $cfg->LDAPUserIdAttribute,
        ];
    my $entry = $ldap->get_entry_by_name( $q->param('name'), $attrs );
    if ( !$entry ) {
        if ( ($author_id) && ( $cfg->ExternalUserManagement ) ) {
            my $user_class = $app->user_class;
            my $user = $user_class->load( $author_id, { cached_ok => 1 } );
            return $cmpnt->translate( 'User [_1]([_2]) not found.',
                $q->param('name'), $author_id )
                unless $user;

            if ( $user->external_id ) {
                $entry
                    = $ldap->get_entry_by_uuid( $user->external_id, $attrs );
                if ($entry) {
                    my $orig_name = $user->name;
                    $user->name( $entry->get_value($attr_uid) );
                    $user->save
                        or $app->log(
                        {   message => $cmpnt->translate(
                                "User '[_1]' cannot be updated.",
                                $user->name
                            ),
                            level    => MT::Log::ERROR(),
                            class    => 'system',
                            category => 'update_user_ldap'
                        }
                        ),
                        return $cmpnt->translate(
                        "User '[_1]' cannot be updated.",
                        $user->name );
                    $app->log(
                        {   message => $cmpnt->translate(
                                "User '[_1]' updated with LDAP login ID.",
                                $orig_name
                            ),
                            level    => MT::Log::INFO(),
                            class    => 'system',
                            category => 'update_user_ldap'
                        }
                    );
                }
            }
        }
    }
    if ( !$entry ) {
        return $cmpnt->translate( 'LDAP user [_1] not found.',
            $q->param('name') );
    }

    unless ($id) {
        $q->param( 'nickname', $entry->get_value($attr_fullname) );
        $q->param( 'email',    $entry->get_value($attr_email) );
        $q->param( 'external_id',
            $entry->get_value( $cfg->LDAPUserIdAttribute ) )
            if ( $cfg->LDAPUserIdAttribute )
            && ( $cfg->ExternalUserManagement );
    }

    return '';
}

sub is_valid_password {
    my $auth = shift;
    my ( $user, $pass, $crypted, $error_ref ) = @_;
    $pass ||= '';

    my $ldap_info = $auth->_login_ldap( $user->name, $pass );
    if ( !defined $ldap_info ) {
        $$error_ref = $auth->errstr;
    }
    return $ldap_info ? 1 : 0;
}

sub ldap {
    my $auth = shift;
    $auth->{ldap} ||= MT::LDAP->new
        or return $auth->error( MT::LDAP->errstr );
}

sub _login_ldap {
    my $auth = shift;
    my ( $name, $pass ) = @_;
    my $ldap = $auth->ldap or return;

    # get user dn
    my $dn = $ldap->get_dn($name);
    if ( !$dn ) {
        return { notfound => 1 };
    }

    # try login
    my $res = $ldap->can_login( $dn, $name, $pass );

    if ( !$res ) {
        return $auth->error( $ldap->errstr );
    }

    return { dn => $dn };
}

sub can_recover_password {0}
sub is_profile_needed    {0}
sub password_exists      {0}

sub validate_credentials {
    my $auth = shift;
    my ( $ctx, %opt ) = @_;
    my $user;
    my $cmpnt = MT->component('enterprise');

    my $app      = $ctx->{app};
    my $username = $ctx->{username};
    my $pass     = $ctx->{password};
    return undef unless ( defined $username ) && ( $username ne '' );

    my $user_class = $app->user_class;
    my ( $message, $ldap_id );
    my $result = MT::Auth::UNKNOWN();
    if ( !$ctx->{session_id} ) {

        # search from LDAP
        my $ldap_info = $auth->_login_ldap( $username, $pass );
        if ( !defined $ldap_info ) {
            my $error = $auth->errstr;
            $app->error($error);
            return $result;
        }
        elsif ( exists $ldap_info->{notfound} ) {
            $user
                = $user_class->load( { name => $username, type => AUTHOR } );
            if ($user) {
                if ( $user->is_active ) {

# Disable this user record since the LDAP
# record no longer exists...
# However, when this user is a administrator of the only, it doesn't disable it.

                    if ( $user->is_superuser ) {
                        my @active_users = MT::Author->load(
                            {   is_superuser => 1,
                                type         => MT::Author::AUTHOR,
                                status       => MT::Author::ACTIVE()
                            }
                        );
                        my $count = @active_users;
                        if ( $count == 1 ) {
                            $app->user($user);
                            return MT::Auth::NEW_LOGIN();
                        }
                    }

                    $user->status( MT::Author::INACTIVE() );
                    $user->save
                        or $app->log(
                        {   message => $cmpnt->translate(
                                "User [_1] cannot be updated.", $username
                            ),
                            level    => MT::Log::ERROR(),
                            class    => 'system',
                            category => 'update_user_ldap'
                        }
                        ),
                        $app->error(
                        $cmpnt->translate(
                            "User cannot be updated: [_1].", $username
                        )
                        ),
                        return MT::Auth::DELETED();
                }
                $app->log(
                    {   message => $cmpnt->translate(
                            "Failed login attempt by user '[_1]' who was deleted from LDAP.",
                            $username
                        ),
                        level => MT::Log::WARNING(),
                    }
                );
                $auth->error(
                    $cmpnt->translate(
                        "Failed login attempt by user '[_1]' who was deleted from LDAP.",
                        $username
                    )
                );
                return MT::Auth::DELETED();
            }
            else {
                return MT::Auth::UNKNOWN();
            }
        }
        $result = MT::Auth::NEW_LOGIN();
        unless ($user) {
            my $id_field_name_ldap = $app->config->LDAPUserIdAttribute
                || $auth->ldap->uid_attr_name;
            my $attrs = [
                $id_field_name_ldap,
                $auth->ldap->uid_attr_name,
                $app->config->LDAPUserFullNameAttribute,
                $app->config->LDAPUserEmailAttribute,
            ];

            # load user environment from LDAP
            my $entry = $auth->ldap->get_entry_by_name( $username, $attrs );

            # load MT::Author
            $user
                = $user_class->load( { name => $username, type => AUTHOR } );
            $ldap_id = $entry->get_value($id_field_name_ldap);
            $ldap_id = '' unless defined $ldap_id;

            if ( !$user ) {
                if ( $app->config->ExternalUserManagement ) {
                    $user
                        = $user_class->load(
                        { external_id => $ldap_id, type => AUTHOR } )
                        if $ldap_id ne '';

                    if ( !$user ) {

                        # create MT::Author
                        my $profile = {
                            name => $entry->get_value(
                                $auth->ldap->uid_attr_name
                                )
                                || $username,
                            nickname => (
                                $entry->get_value(
                                    $app->config->LDAPUserFullNameAttribute
                                    )
                                    || ''
                            ),
                            email => (
                                $entry->get_value(
                                    $app->config->LDAPUserEmailAttribute
                                    )
                                    || ''
                            ),
                            password    => '(none)',
                            external_id => $ldap_id,
                            auth_type   => MT->config->AuthenticationModule,
                        };
                        $app->request( 'ldap_user_profile', $profile );
                        $result = MT::Auth::NEW_USER();
                    }
                    else {
                        my $old_name = $user->name;
                        if ( $user->is_active ) {
                            $user->name($username);
                            $user->save
                                or $app->log(
                                {   message => $cmpnt->translate(
                                        "User '[_1]' cannot be updated.",
                                        $username
                                    ),
                                    level    => MT::Log::ERROR(),
                                    class    => 'system',
                                    category => 'update_user_ldap'
                                }
                                ),
                                $app->error(
                                $cmpnt->translate(
                                    "User '[_1]' cannot be updated.",
                                    $username
                                )
                                ),
                                return MT::Auth::UNKNOWN();
                            $result = MT::Auth::NEW_LOGIN();
                        }
                        $app->log(
                            {   message => $cmpnt->translate(
                                    "User '[_1]' updated with LDAP login name '[_2]'.",
                                    $old_name,
                                    $username
                                ),
                                level    => MT::Log::INFO(),
                                class    => 'system',
                                category => 'update_user_ldap'
                            }
                        );
                    }
                }
                else {

                    # try external_id with lower case username in non-EUM
                    # to save case sensitive database
                    $user = $user_class->load(
                        {   external_id => lc($username),
                            type        => AUTHOR,
                            status      => 1
                        }
                    );
                }
            }
        }

        # sync UUID
        if ( $user && ( exists $ldap_info->{notfound} ) ) {
            if ( $user->is_active
                && ( ( $user->external_id || '' ) ne $ldap_id ) )
            {
                $user->external_id($ldap_id);
                $user->save
                    or $app->log(
                    {   message => $cmpnt->translate(
                            "User cannot be updated: [_1].", $username
                        ),
                        level    => MT::Log::ERROR(),
                        class    => 'system',
                        category => 'update_user_ldap'
                    }
                    ),
                    $app->error(
                    $cmpnt->translate(
                        "User cannot be created: [_1].", $username
                    )
                    ),
                    return MT::Auth::UNKNOWN();
                $app->log(
                    {   message => $cmpnt->translate(
                            "User '[_1]' updated with LDAP login ID.",
                            $username
                        ),
                        level    => MT::Log::INFO(),
                        class    => 'system',
                        category => 'update_user_ldap'
                    }
                );
                $result = MT::Auth::NEW_LOGIN();
            }
            else {

# this is the case where a user with the same name but has different id tries to login
                $app->log(
                    {   message => $cmpnt->translate(
                            "Failed login attempt by user '[_1]'. A user with that username already exists in the system with a different UUID.",
                            $username
                        ),
                        level => MT::Log::WARNING(),
                    }
                );
                $result = MT::Auth::UNKNOWN();
            }
        }
    }
    else {

        # load MT::Author
        $user = $user_class->load( { name => $username, type => AUTHOR } );
        $result = MT::Auth::SUCCESS() if $user;
    }

    # user status validation
    if ( $user && !$user->is_active ) {
        if ( MT::Author::INACTIVE() == $user->status ) {
            $app->error(
                $cmpnt->translate(
                    "User '[_1]' account is disabled.", $username
                )
            );
            $result = MT::Auth::INACTIVE();
            $user   = undef;
        }
        elsif ( MT::Author::PENDING() == $user->status ) {
            $result = MT::Auth::PENDING();

            # leave user in $app - removed later in app
        }
    }

    $app->user($user);
    return $result;
}

sub _get_field_names {
    my $obj = shift;
    my ( $id_directive_name, $name_directive_name ) = @_;
    my $id_field_name_mt;
    my $id_field_name_ldap;
    my $ldap = $obj->ldap;
    my $cfg  = MT->config;
    my $meth;
    if ( $cfg->$id_directive_name ) {
        $id_field_name_ldap = $cfg->$id_directive_name;
        $id_field_name_mt   = 'external_id';
        $meth               = sub {
            my $data = unpack( 'H*', $_[0] );
            $data =~ s/([0-9A-Za-z]{2})/\\$1/g;
            return $data;
        };
    }
    else {
        $id_field_name_ldap
            = $name_directive_name
            ? $cfg->$name_directive_name
            : $ldap->uid_attr_name;
        $id_field_name_mt = 'name';
        $meth = sub { $_[0]; };
    }
    return ( $id_field_name_ldap, $id_field_name_mt, $meth );
}

## Synchronization
sub synchronize {
    my $obj          = shift;
    my $cmpnt        = MT->component('enterprise');
    my $user_updates = $obj->synchronize_author(@_);
    return $obj->error(
        $cmpnt->translate("LDAP users synchronization interrupted.") )
        if ( $user_updates == -1 );
    my $group_updates = $obj->synchronize_group(@_);
    return undef unless defined $group_updates;
    $user_updates + $group_updates;
}

sub synchronize_author {
    my $auth    = shift;
    my $cmpnt   = MT->component('enterprise');
    my (%param) = @_;

    return 0 unless MT->config->ExternalUserManagement;

    # "User" parameter accepts a single object or an array of objects
    my $users;
    $users = $param{User} if exists $param{User};
    if ( $users && ( !ref $users ) ) {
        $users = [$users];
    }

    my $app = MT->instance;

    my $ldap = $auth->ldap;
    unless ($ldap) {
        my $msg = $cmpnt->translate( "Loading MT::LDAP failed: [_1]",
            $auth->errstr );
        MT->log(
            {   class    => 'system',
                category => 'externalusermanagement',
                level    => MT::Log::ERROR(),
                message  => $cmpnt->translate(
                    "External user synchronization failed."),
                metadata => $msg,
            }
        );
        return $auth->error($msg);
    }

    my ( $id_field_name_ldap, $id_field_name_mt, $bin2hex )
        = $auth->_get_field_names( 'LDAPUserIdAttribute', undef );
    my $field_name_uid = $ldap->uid_attr_name;
    my $cfg            = $app->config;

    # Do synchronization process in chunks... 50 at a time?
    my $total_updates = 0;
    my $offset        = 0;
    my $do_admins     = !exists( $param{User} );
    while (1) {
        my @users;
        if ($users) {
            if ( ref($users) eq "ARRAY" ) {
                @users = @$users;
            }
            else {
                @users = ($users);
            }
        }
        elsif ($do_admins) {
            @users = MT::Author->load(
                {   type   => MT::Author::AUTHOR,
                    status => MT::Author::ACTIVE()
                },
                {   join => MT::Permission->join_on(
                        'author_id',
                        {   permissions => "\%'administer'\%",
                            blog_id     => '0',
                        },
                        { 'like' => { 'permissions' => 1 } }
                    ),
                }
            );
        }
        else {
            my @tmp_users = MT::Author->load(
                {   type   => MT::Author::AUTHOR,
                    status => MT::Author::ACTIVE()
                },
                {   sort   => 'id',
                    offset => $offset,
                    limit  => 50,
                }
            );
            $offset += scalar @tmp_users;
            ## is_superuser => 0 does not work on NULLs...
            @users = grep { !$_->is_superuser; } @tmp_users;
        }
        last unless @users;

        my $filter = '(|';
        foreach my $user (@users) {
            my $name = $user->$id_field_name_mt;
            next unless ( defined $name ) && ( $name ne '' );
            $filter
                .= '(' . $id_field_name_ldap . '=' . $bin2hex->($name) . ')';
        }
        $filter .= ')';

        my $attrs = [ $field_name_uid, $cfg->LDAPUserIdAttribute, ];
        my $ldap_entries = $ldap->search_ldap(
            filter => $filter,
            attrs  => $attrs
        );
        if ( !defined $ldap_entries ) {
            if ( $do_admins && ( 0 < scalar(@users) ) ) {
                MT->log(
                    {   class    => 'system',
                        category => 'externalusermanagement',
                        level    => MT::Log::ERROR(),
                        message  => $cmpnt->translate(
                            "LDAP users synchronization interrupted."),
                        metadata => $cmpnt->translate(
                            "An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted."
                        ),
                    }
                );
                return -1;    ## -1 indicates this type of failure
            }
            MT->log(
                {   class    => 'system',
                    category => 'externalusermanagement',
                    level    => MT::Log::ERROR(),
                    message  => $cmpnt->translate(
                        "External user synchronization failed."),
                    metadata => $ldap->errstr . ", filter: $filter",
                }
            );
            return $auth->error( $ldap->errstr );
        }

        my $updated
            = $auth->_sync_users( \@users, $ldap_entries, $field_name_uid,
            $id_field_name_ldap, $id_field_name_mt, $do_admins );
        return -1 if ( $updated == -1 ) && ($do_admins);
        $do_admins = 0;
        $total_updates += $updated;
        last if $users;
    }

    $total_updates ? 1 : 0;
}

sub _sync_users {
    my $obj   = shift;
    my $cfg   = MT->config;
    my $cmpnt = MT->component('enterprise');
    my ( $users, $ldap_entries, $field_name_uid, $id_field_name_ldap,
        $id_field_name_mt, $do_admins )
        = @_;
    if (   $do_admins
        && ( 0 == scalar(@$ldap_entries) )
        && ( 0 < scalar(@$users) ) )
    {
        MT->log(
            {   class    => 'system',
                category => 'externalusermanagement',
                level    => MT::Log::ERROR(),
                message  => $cmpnt->translate(
                    "LDAP users synchronization interrupted."),
                metadata => $cmpnt->translate(
                    "An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted."
                ),
            }
        );
        return -1;    ## -1 indicates this type of failure
    }

    my @disabled;
    my @modified;
    for my $user (@$users) {
        my ($ldap_entry) = grep {
            ( $_->get_value($id_field_name_ldap) || '' ) eq
                ( $user->$id_field_name_mt || '' )
        } @$ldap_entries;
        if ( !$ldap_entry ) {
            if ( $user->is_active ) {

                # check for user by name if we're using UUID
                if ( MT->config->LDAPUserIdAttribute ) {

                    # try to find the LDAP entry based on login name
                    if ( !$user->external_id ) {
                        my $attrs = [ $id_field_name_ldap, ];
                        $ldap_entry
                            = $obj->ldap->get_entry_by_name( $user->name,
                            $attrs );
                        if ($ldap_entry) {
                            my $external_id
                                = $ldap_entry->get_value($id_field_name_ldap)
                                || '';
                            if ( $external_id ne '' ) {
                                $user->external_id($external_id);
                                $user->save;
                            }
                        }
                    }
                }
                if ( !$ldap_entry )
                { # && (!$user->is_superuser || ($user->is_superuser && $admins > 1))) {
                    $user->status(MT::Author::INACTIVE);
                    $user->save;
                    push @disabled, $user->name;
                }
            }
        }
        if ($ldap_entry) {
            my $uid      = $ldap_entry->get_value($field_name_uid);
            my $modified = 0;
            if ( lc( $user->name ) ne lc($uid) )
            {     # TODO: config directive case insensitive comparison?
                $user->name($uid);
                $user->save;
                push @modified, $user->name;
            }
        }
    }
    my $metadata;
    if ( 0 < scalar(@modified) ) {
        $metadata
            = $cmpnt->translate(
            "Information about the following users was modified:")
            . ' '
            . join ", ", @modified;
    }
    if ( 0 < scalar(@disabled) ) {
        if ( $do_admins && ( scalar(@disabled) == scalar(@$users) ) ) {
            ## all administrators are disabled - reverse back what has been done
            for my $user (@$users) {
                $user->status(MT::Author::ACTIVE);
                $user->save;
            }
            MT->log(
                {   class    => 'system',
                    category => 'externalusermanagement',
                    level    => MT::Log::ERROR(),
                    message  => $cmpnt->translate(
                        "LDAP users synchronization interrupted."),
                    metadata => $cmpnt->translate(
                        "An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted."
                    ),
                }
            );
            return -1;    ## -1 indicates this type of failure
        }
        else {
            $metadata .= "\n" if $metadata;
            $metadata
                .= $cmpnt->translate("The following users were disabled:")
                . ' '
                . join ", ", @disabled;
        }
    }
    if ( @modified || @disabled ) {
        MT->log(
            {   class    => 'system',
                category => 'externalusermanagement',
                level    => MT::Log::INFO(),
                message  => $cmpnt->translate("LDAP users synchronized."),
                metadata => $metadata,
            }
        );
        return scalar(@modified) + scalar(@disabled);
    }

    0;
}

sub synchronize_group {
    my $obj = shift;

    my $cmpnt = MT->component('enterprise');
    my $cfg   = MT->config;

    return 0 unless $cfg->ExternalGroupManagement;

    if (!(  ( $cfg->LDAPGroupIdAttribute ) || ( $cfg->LDAPGroupNameAttribute )
        )
        )
    {
        my $message
            = $cmpnt->translate(
            "Synchronization of groups can not be performed without LDAPGroupIdAttribute and/or LDAPGroupNameAttribute being set."
            );
        MT->log(
            {   class    => 'system',
                category => 'externalusermanagement',
                level    => MT::Log::ERROR(),
                message  => $message,
            }
        );
        return undef;    ##$obj->error($message);
    }

    my $ldap = $obj->ldap;
    return $obj->error(
        $cmpnt->translate(
            "Loading MT::LDAP failed: [_1]", MT::LDAP->errstr
        )
    ) unless $ldap;

    my ( $id_field_name_ldap, $id_field_name_mt, $bin2hex )
        = $obj->_get_field_names( 'LDAPGroupIdAttribute',
        'LDAPGroupNameAttribute' );

    my $total_updates = 0;
    my $exclude_filter;

    my $offset = 0;
    while (1) {
        my @groups = MT::Group->load(
            { status => MT::Group::ACTIVE() },
            {   sort   => 'id',
                offset => $offset,
                limit  => 50,
            }
        );
        last unless @groups;
        $offset += scalar @groups;

        my $filter;
        foreach my $group (@groups) {
            my $name = $group->$id_field_name_mt;
            next unless ( defined $name ) && ( $name ne '' );
            $filter
                .= '(' . $id_field_name_ldap . '=' . $bin2hex->($name) . ')';
        }
        if ( defined($filter) ) {
            $exclude_filter .= $filter;
            $filter = "(|$filter)";

            my $ldap_entries = $obj->_search_groups( $filter, 1 );
            my $updated
                = $obj->_sync_existing_groups( \@groups, $ldap_entries,
                $id_field_name_ldap, $id_field_name_mt );
            $total_updates += $updated;
        }
    }

    $exclude_filter = "(!(|$exclude_filter))" if $exclude_filter;
    my $ldap_entries = $obj->_search_groups( $exclude_filter, 0 );
    my $updated = $obj->_sync_new_groups( $ldap_entries, $id_field_name_ldap,
        $id_field_name_mt );
    $total_updates += $updated;
    $total_updates ? 1 : 0;
}

sub synchronize_group_user {
    my $obj = shift;
    my (%param) = @_;

    return 0 unless MT->config->ExternalGroupManagement;

    my $cmpnt = MT->component('enterprise');

    # "User" parameter accepts a single object or an array of objects
    my $users;
    $users = $param{User} if exists $param{User};
    if ( $users && ( 'ARRAY' ne ref($users) ) ) {
        $users = [$users];
    }
    return 0 unless @$users;

    my $user_filter = $obj->_build_filter_users($users) if $users;
    return 0 if !defined($user_filter);

    my $ldap_entries = $obj->_search_groups( $user_filter, 1 );

    my ( $id_field_name_ldap, $id_field_name_mt, $bin2hex )
        = $obj->_get_field_names( 'LDAPGroupIdAttribute',
        'LDAPGroupNameAttribute' );

    my %groups_seen;
    my @modified;
    for my $ldap_entry (@$ldap_entries) {
        my $gid = $ldap_entry->get_value($id_field_name_ldap);
        my $group = MT::Group->load( { $id_field_name_mt => $gid },
            { limit => 1, } );

        if ( exists $param{User} ) {
            ## perform specific user sync
            if ($group) {
                if ( $group->is_active ) {
                    my $mod = $obj->_sync_existing_group( $group, $ldap_entry,
                        \@modified );
                    require MT::Association;
                    for my $user (@$users) {
                        unless (
                            MT::Association->count(
                                {   author_id => $user->id,
                                    group_id  => $group->id,
                                    type => MT::Association::USER_GROUP(),
                                }
                            )
                            )
                        {
                            $group->add_user($user);
                            push @modified, $group->name
                                unless $mod;
                        }
                    }
                }
            }
            else {
                $group = $obj->_sync_new_group($ldap_entry);
                $group->add_user($_) foreach @$users;
            }
        }
        else {
            if ( ($group) && ( $group->is_active ) ) {
                $obj->_sync_existing_group( $group, $ldap_entry, \@modified );
                $obj->_sync_group_members( $ldap_entry, $group, 0 );
            }
            else {
                $group = $obj->_sync_new_group($ldap_entry);
                $obj->_sync_group_members( $ldap_entry, $group, 1 );
            }
        }
        $groups_seen{ $group->id } = 1 if $group;
    }
    my $terms = {};
    my $args  = {};
    if ( 0 < scalar( keys %groups_seen ) ) {
        $terms->{'id'} = { not => [ keys(%groups_seen) ] };
    }
    for my $user (@$users) {
        my $iter = $user->group_iter( $terms, $args );
        while ( my $group = $iter->() ) {
            $group->remove_user($user);
            push @modified, $group->name;
        }
    }
    if ( 0 < scalar(@modified) ) {
        my $names = join ',', @modified;
        MT->log(
            {   class    => 'system',
                category => 'externalgroupmanagement',
                level    => MT::Log::INFO(),
                message  => $cmpnt->translate(
                    "LDAP groups synchronized with existing groups."),
                metadata => $cmpnt->translate(
                    "Information about the following groups was modified:")
                    . " $names",
            }
        );
    }
}

sub _search_groups {
    my $obj = shift;
    my ( $name_filter, $dolog ) = @_;
    my $cfg   = MT->config;
    my $ldap  = $obj->ldap;
    my $cmpnt = MT->component('enterprise');

    my $filter = '(&' . ( $name_filter ? $name_filter : '' );
    $filter .= $cfg->LDAPGroupFilter || '(objectClass=*)';
    $filter .= ')';
    my $attrs = [
        $cfg->LDAPGroupNameAttribute || $ldap->uid_attr_name,
        $cfg->LDAPGroupFullNameAttribute,
        $cfg->LDAPGroupMemberAttribute,
        $cfg->LDAPGroupIdAttribute,
    ];
    my $ldap_entries = $ldap->search_ldap(
        base => $cfg->LDAPGroupSearchBase || $ldap->{base},
        filter => $filter,
        attrs  => $attrs
    );
    MT->log(
        {   class    => 'system',
            category => 'externalgroupmanagement',
            level    => MT::Log::INFO(),
            message  => $cmpnt->translate(
                "No LDAP group was found using the filter provided."),
            metadata => $cmpnt->translate(
                "The filter used to search for groups was: '[_1]'. Search base was: '[_2]'",
                $filter ? $filter : $cmpnt->translate('(none)'),
                $cfg->LDAPGroupSearchBase || $ldap->{base}
            ),
        }
        )
        if ( !defined($ldap_entries) || ( 0 == scalar(@$ldap_entries) ) )
        && $dolog;
    return $ldap_entries;
}

sub _sync_existing_groups {
    my $obj = shift;
    my ( $groups, $ldap_entries, $id_field_name_ldap, $id_field_name_mt )
        = @_;

    my $cmpnt = MT->component('enterprise');
    my %disabled;
    my @modified;
    my $modified = 0;
    while ( my $group = shift(@$groups) ) {
        my ($ldap_entry) = grep {
            ( $_->get_value($id_field_name_ldap) || '' ) eq
                ( $group->$id_field_name_mt || '' )
        } @$ldap_entries;
        if ( !$ldap_entry ) {
            if ( $group->is_active ) {

                # check for group by name if we're using UUID
                ### TBD : DO WE DO THIS FOR GROUPS AS WELL?
#if (MT->config->LDAPGroupIdAttribute) {
#    # try to find the LDAP entry based on login name
#    if (!$group->external_id) {
#        my $attrs = [
#                $id_field_name_ldap,
#            ];
#        $ldap_entry = $obj->ldap->get_entry_by_name($group->name, $attrs);
#        if ($ldap_entry) {
#            my $external_id = $ldap_entry->get_value($id_field_name_ldap) || '';
#            if ($external_id ne '') {
#                $group->external_id($external_id);
#                $group->save;
#            }
#        }
#    }
#}
#if (!$ldap_entry) {
                $group->status(MT::Group::INACTIVE);
                $group->save;
                $disabled{ $group->name } = $group;

                #}
            }
        }
        if ($ldap_entry) {
            $modified = $obj->_sync_existing_group( $group, $ldap_entry,
                \@modified );
            $modified += $obj->_sync_group_members( $ldap_entry, $group, 0 );
        }
    }
    my $metadata;
    if ( 0 < scalar(@modified) ) {
        $metadata
            = $cmpnt->translate(
            "Information about the following groups was modified:")
            . ' '
            . join ", ", @modified;
    }
    if ( 0 < scalar( keys %disabled ) ) {
        $metadata .= "\n" if $metadata;
        $metadata
            .= $cmpnt->translate("The following groups were deleted:") . ' '
            . join ", ", keys %disabled;
    }
    if ( @modified || %disabled ) {
        MT->log(
            {   class    => 'system',
                category => 'externalgroupmanagement',
                level    => MT::Log::INFO(),
                message  => $cmpnt->translate(
                    "LDAP groups synchronized with existing groups."),
                metadata => $metadata,
            }
        );
        $_->remove foreach values %disabled;
        return scalar(@modified) + scalar( keys %disabled );
    }

    $modified;
}

sub _sync_existing_group {
    my $obj = shift;
    my ( $group, $ldap_entry, $modified ) = @_;
    my $numbers        = 0;
    my $name_attr_name = MT->config->LDAPGroupNameAttribute
        || $obj->ldap->uid_attr_name;
    if ($name_attr_name) {
        my $name = $ldap_entry->get_value($name_attr_name);
        if ( $group->name ne $name ) {
            $group->name($name);
            $numbers++;
        }
    }
    if ($numbers) {
        $group->save;
        push @$modified, $group->name;
    }
    $numbers;
}

sub _sync_new_groups {
    my $obj = shift;
    my ( $ldap_entries, $id_field_name_ldap, $id_field_name_mt ) = @_;
    my $cfg = MT->config;

    my $updated = 0;
    for my $ldap_entry (@$ldap_entries) {
        my $group = MT::Group->load(
            {   $id_field_name_mt =>
                    $ldap_entry->get_value($id_field_name_ldap),
            },
            { limit => 1, }
        );
        if ( !$group ) {
            $group = $obj->_sync_new_group($ldap_entry);
            return 0 if !$group;
            $updated += $obj->_sync_group_members( $ldap_entry, $group, 1 );
        }
    }
    $updated;
}

sub _sync_new_group {
    my $obj          = shift;
    my ($ldap_entry) = @_;
    my $cfg          = MT->config;

    my $cmpnt = MT->component('enterprise');
    require MT::Util;
    my $enc = $cfg->PublishCharset;

    my $name_attr 
        = $cfg->LDAPGroupNameAttribute
        || $cfg->LDAPGroupIdAttribute
        || $obj->ldap->uid_attr_name;
    my $group = MT::Group->new;
    $group->name(

        $ldap_entry->get_value($name_attr)

    );
    $group->display_name(
        $ldap_entry->get_value( $cfg->LDAPGroupFullNameAttribute )

    ) if $cfg->LDAPGroupFullNameAttribute;
    $group->external_id(
        $ldap_entry->get_value( $cfg->LDAPGroupIdAttribute ) )
        if $cfg->LDAPGroupIdAttribute;
    $group->status( MT::Group::ACTIVE() );

    $group->save
        or MT->log(
        {   message => $cmpnt->translate(
                "Failed to create a new group: [_1]",
                $group->errstr
            ),
            level    => MT::Log::ERROR(),
            class    => 'system',
            category => 'synchronize_group'
        }
        ),
        return $group->error(
        $cmpnt->translate(
            "Failed to create a new group: [_1]",
            $group->errstr
        )
        );

    return $group;
}

sub _sync_group_members {
    my $obj = shift;
    my ( $ldap_entry, $group, $new_group ) = @_;
    my $cfg = MT->config;

    my $cmpnt         = MT->component('enterprise');
    my $uid_to_search = $cfg->LDAPUserGroupMemberAttribute;
    if ( !$uid_to_search ) {
        MT->log(
            {   message => $cmpnt->translate(
                    '[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.',
                    'LDAPUserGroupMemberAttribute'
                ),
                level => MT::Log::WARNING(),
            }
        );
        return 0;
    }
    if ( !$cfg->LDAPGroupMemberAttribute ) {
        MT->log(
            {   message => $cmpnt->translate(
                    '[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.',
                    'LDAPGroupMemberAttribute'
                ),
                level => MT::Log::WARNING(),
            }
        );
        return 0;
    }
    my @members = $ldap_entry->get_value( $cfg->LDAPGroupMemberAttribute );

    my ( $id_field_name_ldap, $id_field_name_mt, $bin2hex )
        = $obj->_get_field_names( 'LDAPUserIdAttribute', undef );

    my %ldap_members;
    my $i      = 0;
    my $filter = '(|';
    for my $member (@members) {
        if (   ( $uid_to_search eq 'dn' )
            || ( $uid_to_search eq 'distinguishedName' ) )
        {
            my $m = $member;
            $m =~ s/^(.*?[^\\]),.*$/$1/;    # strip DN to make RDN.
            $filter .= '(' . $m . ')';
        }
        else {
            $filter .= "($uid_to_search=$member)";
        }
        if ( 20 == ++$i ) {    # each iteration has 20 users in the query
            $filter .= ')';
            $filter = '(&' . $filter;
            $filter .= $obj->{filter} if $obj->{filter};
            $filter .= ')';
            my $attrs = [ $obj->ldap->uid_attr_name, $id_field_name_ldap, ];
            my $ldap_group_members = $obj->ldap->search_ldap(
                base   => $obj->ldap->{base},
                filter => $filter,
                attrs  => $attrs
            );
            for my $ldap_group_member (@$ldap_group_members) {
                my $id = $ldap_group_member->get_value($id_field_name_ldap);
                $ldap_members{$id} = $ldap_group_member;
            }
            $i      = 0;
            $filter = '(|';
        }
    }
    if ( $i > 0 ) {

        # process remaining fraction
        $filter .= ')';
        $filter = '(&' . $filter;
        $filter .= $obj->{filter} if $obj->{filter};
        $filter .= ')';
        my $attrs = [ $obj->ldap->uid_attr_name, $id_field_name_ldap, ];
        my $ldap_group_members = $obj->ldap->search_ldap(
            base   => $obj->ldap->{base},
            filter => $filter,
            attrs  => $attrs
        );
        for my $ldap_group_member (@$ldap_group_members) {
            my $id = $ldap_group_member->get_value($id_field_name_ldap);
            $ldap_members{$id} = $ldap_group_member;
        }
    }

    my $modified = 0;
    my @metadata_added;
    my @metadata_removed;

    my %mt_members;

    ## remove existing members who are not members of the group in LDAP now
    my $iter = $group->user_iter();
    while ( my $user = $iter->() ) {
        if ( exists $ldap_members{ $user->$id_field_name_mt } ) {
            $mt_members{ $user->$id_field_name_mt } = $user;
        }
        else {
            $group->remove_user($user);
            $modified++;
            push @metadata_removed, $user->name;
        }
    }

    ## add new members who are not members of the group
    for my $ldap_member_name ( grep !$mt_members{$_}, keys %ldap_members ) {
        my $user = MT::Author->load(
            {   $id_field_name_mt => $ldap_member_name,
                type              => AUTHOR,
            }
        );
        if ($user) {
            $group->add_user($user);
            $modified++;
            push @metadata_added, $user->name;
        }
    }

    my $metadata
        = scalar(@metadata_removed) > 0
        ? $cmpnt->translate('Members removed: ')
        . join( ', ', @metadata_removed ) . "\n"
        : '';
    $metadata .=
        scalar(@metadata_added) > 0
        ? $cmpnt->translate('Members added: ')
        . join( ', ', @metadata_added ) . "\n"
        : '';
    if ($modified) {
        MT->log(
            {   class    => 'system',
                category => 'externalgroupmanagement',
                level    => MT::Log::INFO(),
                message  => $cmpnt->translate(
                    "Memberships in the group '[_2]' (#[_3]) were changed as a result of synchronizing with the external directory.",
                    $modified, $group->name, $group->id
                ),
                metadata => $metadata,
            }
        );
    }

    return $modified;
}

sub _build_filter_users {
    my $obj     = shift;
    my ($users) = @_;
    my $cfg     = MT->config;

    my $cmpnt  = MT->component('enterprise');
    my $filter = q();
    my ( $id_field_name_ldap, $id_field_name_mt, $bin2hex )
        = $obj->_get_field_names( 'LDAPUserIdAttribute', undef );
    my @users;
    if ($users) {
        my $uid_to_search = $cfg->LDAPUserGroupMemberAttribute
            || $obj->ldap->uid_attr_name;
        if ( !$uid_to_search ) {
            my $error
                = $cmpnt->translate(
                'LDAPUserGroupMemberAttribute must be set to enable synchronizing of members of groups.'
                );
            MT->log(
                {   message => $error,
                    level   => MT::Log::ERROR(),
                }
            );
            return q();
        }
        if ( ref($users) eq "ARRAY" ) {
            @users = @$users;
        }
        else {
            @users = ($users);
        }
        my $uid_filter;
        for my $user (@users) {
            my $uid = $user->$id_field_name_mt;
            $uid_filter
                .= '(' . $id_field_name_ldap . '=' . $bin2hex->($uid) . ')';
        }
        $uid_filter = "(|$uid_filter)" if $uid_filter;
        my $attrs        = [$uid_to_search];
        my $ldap_entries = $obj->ldap->search_ldap(
            filter => $uid_filter,
            attrs  => $attrs
        );
        my $member_attr = $cfg->LDAPGroupMemberAttribute;
        for my $ldap_entry (@$ldap_entries) {
            my $member_attr_value;
            if (   ( $uid_to_search eq 'dn' )
                || ( $uid_to_search eq 'distinguishedName' ) )
            {
                $member_attr_value = $ldap_entry->dn;
                $member_attr_value =~ s/\\,/\\\\,/g;
            }
            else {
                $member_attr_value = $ldap_entry->get_value($uid_to_search);
            }
            $filter .= "($member_attr=$member_attr_value)";
        }
        $filter = "(|$filter)" if $filter;
    }
    return $filter;
}

1;

__END__


=head1 NAME

MT::Auth::LDAP - MT LDAP authentication and synchronization interface

=head1 SYNOPSIS

    use MT::Auth;
    MT::Auth->is_valid_password("username", "password");

=head1 METHODS

=over 4

=item * task_synchronize

The routine depends on a lot of configuration directives, mostly to abstract
away the differences between such LDAP implemenation as OpenLDAP, Active
Directory and Novell eDirectory.

    $object->task_synchronize;

Typically the method will not be called directly, but rather called by
the base class / factory, MT::Auth.

=head1 AUTHOR & COPYRIGHTS

Please see the I<MT> manpage for author, copyright, and license information.

=cut
