# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::Wizard;

use strict;

use Encode;
use URI;

sub template_hdlr {
    return sub {
        my ( $ctx, $args, $cond ) = @_;
        $ctx->var( 'auth_ldap', 1 ) if $ctx->var('authtype');

        if ( my $authurl = $ctx->var('authurl') ) {
            $ctx->var( 'authurl', encode_authurl($authurl) );
        }

        return $ctx->build(<<EOT);
<mt:if name="auth_ldap">#======== LDAP authentication ========

AuthenticationModule LDAP<mt:if name="authurl">
LDAPAuthURL <mt:var name="authurl"></mt:if><mt:if name="binddn">
LDAPAuthBindDN <mt:var name="binddn"></mt:if><mt:if name="authpassword">
LDAPAuthPassword <mt:var name="authpassword"></mt:if><mt:if name="saslmechanism">
LDAPAuthSASLMechanism <mt:var name="saslmechanism"></mt:if><mt:if name="eum">
ExternalUserManagement <mt:var name="eum">
ExternalGroupManagement <mt:var name="eum"><mt:if name="eum_freq">
ExternalUserSyncFrequency <mt:var name="eum_freq"></mt:if><mt:if name="eum_group_name">
LDAPGroupNameAttribute <mt:var name="eum_group_name"></mt:if><mt:if name="eum_group_id">
LDAPGroupIdAttribute <mt:var name="eum_group_id"></mt:if><mt:if name="eum_group_fullname">
LDAPGroupFullNameAttribute <mt:var name="eum_group_fullname"></mt:if><mt:if name="eum_group_member">
LDAPGroupMemberAttribute <mt:var name="eum_group_member"></mt:if><mt:if name="eum_group_searchbase">
LDAPGroupSearchBase <mt:var name="eum_group_searchbase"></mt:if><mt:if name="eum_group_filter">
LDAPGroupFilter <mt:var name="eum_group_filter"></mt:if><mt:if name="eum_user_id">
LDAPUserIdAttribute <mt:var name="eum_user_id"></mt:if><mt:if name="eum_user_email">
LDAPUserEmailAttribute <mt:var name="eum_user_email"></mt:if><mt:if name="eum_user_fullname">
LDAPUserFullNameAttribute <mt:var name="eum_user_fullname"></mt:if><mt:if name="eum_user_member">
LDAPUserGroupMemberAttribute <mt:var name="eum_user_member"></mt:if><mt:else>
ExternalUserManagement 0
ExternalGroupManagement 0</mt:if>
</mt:if>
EOT
    };
}

sub cfg_ldap_auth {
    my $app   = shift;
    my %param = @_;

    $param{set_static_uri_to} = $app->param('set_static_uri_to');

    # set static web path
    $app->config->set( 'StaticWebPath', $param{set_static_uri_to} );

    $param{use_ldap} = 1 if $param{authtype};
    $param{config} = $app->serialize_config(%param);

    # set master data
    my $saslmechanism;
    push @$saslmechanism, { id => 'PLAIN', name => $app->translate('PLAIN') };

    eval 'require Authen::SASL';
    unless ($@) {
        push @$saslmechanism,
            { id => 'CRAM-MD5', name => $app->translate('CRAM-MD5') };
        push @$saslmechanism,
            { id => 'DIGEST-MD5', name => $app->translate('Digest-MD5') };
        push @$saslmechanism,
            { id => 'LOGIN', name => $app->translate('Login') };
    }

    foreach (@$saslmechanism) {
        if ( $_->{id} eq $param{saslmechanism} ) {
            $_->{selected} = 1;
        }
    }
    $param{sasl_loop} = $saslmechanism;

    # set current mode options
    $param{mode_auth}    = 1;
    $param{current_mode} = 'cfg_ldap_auth';
    $param{back_mode}    = 'optional';

    eval { require Net::LDAP };
    $param{has_net_ldap} = $@ ? 0 : 1;

    # checks
    if ( $app->param('test') ) {

        # if check successfully and push continue then goto next step
        my $ok            = 1;
        my $authurl       = $param{authurl};
        my $binddn        = $param{binddn};
        my $authpassword  = $param{authpassword};
        my $saslmechanism = $param{saslmechanism} || 'PLAIN';

        $app->config->LDAPAuthURL( encode_authurl($authurl) );
        $app->config->LDAPAuthBindDN($binddn);
        $app->config->LDAPAuthPassword($authpassword);
        $app->config->LDAPAuthSASLMechanism($saslmechanism)
            if exists $param{saslmechanism};

        # test loading LDAP module
        require MT::LDAP;
        my $ldap = MT::LDAP->new
            or $ok = 0;

        # test log into the LDAP
        if ($ok) {
            $ok = 0;
            my $dn = $ldap->get_dn( $param{test_userid} );
            if ($dn) {
                my $res = $ldap->can_login( $dn, $param{test_userid},
                    $param{test_password} );
                $ok = 1 if $res;
            }
        }

        if ($ok) {
            $param{success} = 1;
        }
        else {
            $param{connect_error} = 1;
            $param{error} = $ldap ? $ldap->errstr : MT::LDAP->errstr;
        }
    }

    $app->build_page( "cfg_ldap.tmpl", \%param );
}

sub cfg_ldap_eum {
    my $app   = shift;
    my %param = @_;

    delete $param{eum} unless $app->param('eum');

    $param{set_static_uri_to} = $app->param('set_static_uri_to');

    # set static web path
    $app->config->set( 'StaticWebPath', $param{set_static_uri_to} );

    $param{config} = $app->serialize_config(%param);

    # set current mode options
    $param{mode_eum}     = 1;
    $param{current_mode} = 'cfg_ldap_eum';
    $param{back_mode}    = 'cfg_ldap_auth';

    # checks
    if ( $app->param('test') ) {

        # connect to the LDAP
        my $authurl       = $param{authurl};
        my $binddn        = $param{binddn};
        my $authpassword  = $param{authpassword};
        my $saslmechanism = $param{saslmechanism} || 'PLAIN';
        my $group_filter  = $param{eum_group_filter} || '';
        my $search_base   = $param{eum_group_searchbase} || '';

        $app->config->LDAPAuthURL( encode_authurl($authurl) );
        $app->config->LDAPAuthBindDN($binddn);
        $app->config->LDAPAuthPassword($authpassword);
        $app->config->LDAPAuthSASLMechanism($saslmechanism)
            if exists $param{saslmechanism};

        require MT::LDAP;
        my $ldap = MT::LDAP->new;

        # loading groups
        my $filter = '(&' . ( $group_filter || '(objectClass=group)' ) . ')';
        my $attrs = [ 'cn', ];
        my $ldap_entries = $ldap->search_ldap(
            base => $param{eum_group_searchbase} || $ldap->{base},
            filter    => $filter,
            attrs     => $attrs,
            sizelimit => 10,
        );

        my $groups;
        my $entry_found = 0;
        foreach my $group_entry (@$ldap_entries) {
            $entry_found = 1;

            push @$groups, { cn => $group_entry->get_value('cn') || '', };
        }
        $param{group_loop}        = $groups if $groups;
        $param{group_found}       = $entry_found;
        $param{eum_search_result} = 1;
        $param{success}           = 1;
    }

    $app->build_page( "cfg_ldap.tmpl", \%param );
}

sub cfg_ldap_mapping {
    my $app   = shift;
    my %param = @_;

    $param{set_static_uri_to} = $app->param('set_static_uri_to');

    # set static web path
    $app->config->set( 'StaticWebPath', $param{set_static_uri_to} );

    $param{config} = $app->serialize_config(%param);

    # set current mode options
    $param{mode_mapping} = 1;
    $param{current_mode} = 'cfg_ldap_mapping';
    $param{back_mode}    = 'cfg_ldap_eum';

    # checks
    if ( $app->param('test') ) {

        # connect to the LDAP
        my $authurl       = $param{authurl};
        my $binddn        = $param{binddn};
        my $authpassword  = $param{authpassword};
        my $saslmechanism = $param{saslmechanism} || 'PLAIN';
        my $group_filter  = $param{eum_group_filter} || '';
        my $search_base   = $param{eum_group_searchbase} || '';

        $app->config->LDAPAuthURL( encode_authurl($authurl) );
        $app->config->LDAPAuthBindDN($binddn);
        $app->config->LDAPAuthPassword($authpassword);
        $app->config->LDAPAuthSASLMechanism($saslmechanism)
            if exists $param{saslmechanism};

        require MT::LDAP;
        my $ldap = MT::LDAP->new;

        # loading groups
        my $filter = '(&' . ( $group_filter || '(objectClass=group)' ) . ')';
        my $attrs = [
            $param{eum_group_id},       $param{eum_group_name},
            $param{eum_group_fullname}, $param{eum_group_member},
        ];
        my $ldap_entries = $ldap->search_ldap(
            base => $param{eum_group_searchbase} || $ldap->{base},
            filter    => $filter,
            attrs     => $attrs,
            sizelimit => 10,
        );

        my $groups;
        my $entry_found   = 0;
        my $found_msg     = $app->translate("Found");
        my $not_found_msg = $app->translate("Not Found");
        foreach my $group_entry (@$ldap_entries) {
            $entry_found = 1;
            my $members = $group_entry->get_value( $param{eum_group_member},
                asref => 1 );
            my ( $member, $member_count ) = ( '', 0 );
            if ( defined $members ) {
                $member_count = scalar @$members;
                $member = $member_count ? $members->[0] : '';
                if (   ( $param{eum_user_member} eq 'dn' )
                    || ( $param{eum_user_member} eq 'distinguishedName' ) )
                {
                    $member =~ s/^.*?[^\\]\=(.*?[^\\]),.*$/$1/
                        ;    # strip DN to make RDN.
                }
            }
            push @$groups,
                {
                group_id => $group_entry->get_value( $param{eum_group_id} )
                ? $found_msg
                : $not_found_msg,
                group_name =>
                    $group_entry->get_value( $param{eum_group_name} ) || '',
                group_fullname =>
                    $group_entry->get_value( $param{eum_group_fullname} )
                    || '',
                group_member       => $member,
                group_member_count => $member_count,
                };
        }
        $param{group_loop} = $groups if $groups;
        $param{group_found} = $entry_found;

        # loading users
        $attrs = [
            $param{eum_user_id}       || '',
            $param{eum_user_email}    || '',
            $param{eum_user_fullname} || '',
            $param{eum_user_member}   || '',
        ];
        $ldap_entries = $ldap->search_ldap(
            base      => $ldap->{base},
            filter    => $ldap->{filter},
            attrs     => $attrs,
            sizelimit => 10,
        ) or $param{error} = $ldap->errstr;
        $entry_found = 0;
        my $users;
        foreach my $user_entry (@$ldap_entries) {
            $entry_found = 1;

            # load groups for each users
            my $user_group_ident;
            if (   ( $param{eum_user_member} eq 'dn' )
                || ( $param{eum_user_member} eq 'distinguishedName' ) )
            {
                $user_group_ident = $user_entry->dn();
            }
            else {
                $user_group_ident
                    = $user_entry->get_value( $param{eum_user_member} );
            }
            my $user_group_filter = sprintf( '(|(%s=%s))',
                $param{eum_group_member},
                $user_group_ident );
            my $user_groups = $ldap->search_ldap(
                attrs =>
                    [ $param{eum_group_fullname}, $param{eum_group_name}, ],
                base => $param{eum_group_searchbase} || $ldap->{base},
                filter    => $user_group_filter,
                sizelimit => 10,
            ) or $param{error} = $ldap->errstr;
            my $user_group_count = scalar @$user_groups;
            my $user_group
                = $user_group_count
                ? $user_groups->[0]->get_value( $param{eum_group_fullname} )
                : '';
            push @$users, {
                user_id => $user_entry->get_value( $param{eum_user_id} )
                ? $found_msg
                : $not_found_msg,
                user_email => $user_entry->get_value( $param{eum_user_email} )
                    || '',
                user_fullname =>
                    $user_entry->get_value( $param{eum_user_fullname} )
                    || '',
                user_group       => $user_group,
                user_group_count => $user_group_count,

            };
        }
        $param{user_loop}         = $users if $users;
        $param{user_found}        = $entry_found;
        $param{eum_search_result} = 1;
        $param{success}           = 1;
    }

    $app->build_page( "cfg_ldap.tmpl", \%param );
}

sub encode_authurl {
    my ($url) = @_;
    $url = Encode::decode( 'utf8', $url ) unless Encode::is_utf8($url);
    Encode::encode( 'utf8', URI->new($url)->as_string );
}

1;
