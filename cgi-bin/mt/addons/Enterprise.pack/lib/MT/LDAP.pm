# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::LDAP;

use strict;
use base qw( MT::ErrorHandler );

use Net::LDAP qw(LDAP_SUCCESS LDAP_PROTOCOL_ERROR LDAP_SIZELIMIT_EXCEEDED);
use URI;

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    $obj->init(@_);
}

sub init {
    my $ldap = shift;
    my %arg  = @_;

    my $cfg           = MT->config;
    my $auth_ldap_url = $cfg->LDAPAuthURL;

    my $uri = URI->new($auth_ldap_url);
    return MT::LDAP->error(
        MT->translate( "Invalid LDAPAuthURL scheme: [_1].", $uri->scheme ) )
        if ( $uri->scheme ne 'ldap' ) && ( $uri->scheme ne 'ldaps' );

    die MT->translate(
        "Either your server does not have [_1] installed, the version that is installed is too old, or [_1] requires another module that is not installed.",
        'Net::LDAP'
    ) if $Net::LDAP::VERSION < 0.34;

    my $server = $uri->host_port;

    $ldap->{__bound} = 0;
    $ldap->{base}    = $uri->dn;
    $ldap->{base} ||= '';
    my @attr = $uri->attributes;
    $ldap->{uid_attr_name} = $attr[0];   #like mod_auth_ldap, we ignore others
    $ldap->{uid_attr_name} ||= 'uid';

    if ( $uri->query ) {
        my @query = split( /\?/, $uri->query );
        if ( ( scalar @query ) > 1 ) {
            if ( $query[1] ) {
                $ldap->{scope} = $uri->scope;
            }
        }
    }

    $ldap->{scope} ||= 'sub';
    $ldap->{filter} = $uri->filter;
    $ldap->{filter} ||= '';

    $ldap->{bind_dn} = $cfg->LDAPAuthBindDN;
    $ldap->{bind_dn} ||= '';
    $ldap->{bind_password} = $cfg->LDAPAuthPassword;
    $ldap->{bind_password} ||= '';
    $ldap->{sasl_mechanism} = $cfg->LDAPAuthSASLMechanism;
    $ldap->{sasl_mechanism} ||= '';

    ## 'raw' option is required to give an order to Net::LDAP to decode strings.
    ## /(?!)/ is the pattern that never match at anything.
    ## using this means all columns will be decoded.
    my $uid = $cfg->LDAPUserIdAttribute;
    my $raw = $uid ? qr/^$uid$/ : qr/(?!)/;
    if ( $uri->scheme eq 'ldaps' ) {
        require Net::LDAPS;
        $ldap->{ldap} = Net::LDAPS->new( $server, raw => $raw );
    }
    else {
        $ldap->{ldap} = Net::LDAP->new( $server, raw => $raw );
    }
    if ( !$ldap->{ldap} ) {
        my $err = $@;
        my $errstr
            = MT->translate( "Error connecting to LDAP server [_1]: [_2]",
            $server, $err );
        return MT::LDAP->error($errstr);
    }
    ## $ldap->bind_ldap or return MT::LDAP->error($ldap->errstr);
    $ldap;
}

sub uid_attr_name {
    my $this = shift;
    $this->{uid_attr_name};
}

sub ldap {
    my $this = shift;
    $this->bind_ldap unless $this->{__bound};
    $this->{ldap};
}

sub search_ldap {
    my $this  = shift;
    my (%opt) = @_;
    my $ldap  = $this->ldap;
    my $base  = $opt{base} || $this->{base};
    my $scope = $opt{scope} || $this->{scope} || 'sub';

    my $res = $ldap->search(
        base      => $base,
        scope     => $scope,
        filter    => $opt{filter},
        attrs     => $opt{attrs},
        sizelimit => $opt{sizelimit} ? $opt{sizelimit} : 0,
    );

    if ( $res->code != LDAP_SUCCESS && $res->code != LDAP_SIZELIMIT_EXCEEDED )
    {
        return $this->error(
            MT->translate( "User not found in LDAP: [_1]", $res->error ) );
    }

    my @entries = $res->entries;
    return \@entries;
}

sub bind_ldap {
    my $this     = shift;
    my (%params) = @_;
    my $ldap     = $this->{ldap};
    my $res;

    my $password = $this->{bind_password};
    my $user     = $this->{bind_dn};
    my $dn       = $this->{bind_dn};

    if (%params) {
        $password = $params{password};
        $user     = $params{user};
        $dn       = $params{dn};
    }

    if ( !$dn ) {
        $res = $ldap->bind;
    }
    else {
        if ( $this->{sasl_mechanism} eq 'PLAIN' ) {
            $res = $ldap->bind( $dn, password => $password );
        }
        else {
            require Authen::SASL;
            my $sasl = Authen::SASL->new(
                mechanism => $this->{sasl_mechanism},
                callback  => {
                    pass => $password,
                    user => $user,
                },
            );
            $res = $ldap->bind( $dn, sasl => $sasl );
        }
    }

    if ( $res->code ) {
        print STDERR "Error during bind: " . $res->error_text . "\n"
            if $MT::DebugMode;
        return $this->error(
            MT->translate(
                "Binding to LDAP server failed: [_1]",
                $res->error
            )
        );
    }

    $this->{__bound} = 1;

    return $res;
}

sub can_login {
    my $this = shift;
    my ( $dn, $user, $pass ) = @_;

    # Now, rebind using the dn/username/password we are attempting
    # to authenticate with.
    my $res = $this->bind_ldap(
        dn       => $dn,
        user     => $user,
        password => $pass,
    );

    # Now, rebind using BindDN configuration settings...
    $this->bind_ldap;

    # If we succeeded in our authenticated bind, $res should be defined.
    defined $res ? 1 : undef;
}

sub unbind_ldap {
    my $this = shift;
    my $ldap = $this->{ldap};
    return unless $this->{__bound};
    $this->{__bound} = 0;
    return unless $ldap;
    my $mesg = $ldap->unbind;
    if ( $mesg->code ) {
        print STDERR "Error during unbind_ldap: " . $mesg->error_text . "\n"
            if $MT::DebugMode;
    }
    $mesg;
}

sub _get_entry {
    my $this = shift;
    my ( $filter, $attrs, $key ) = @_;
    my $res = $this->ldap->search(
        base   => $this->{base},
        scope  => $this->{scope},
        filter => $filter,
        attrs  => $attrs
    );

    if ( $res->code ) {
        return $this->error(
            MT->translate( "User not found in LDAP: [_1]", $res->error ) );
    }

    my $count = $res->count;
    if ( $count != 1 ) {
        return $this->error(
            ( $count > 0 )
            ? MT->translate(
                "More than one user with the same name found in LDAP: [_1]",
                $count )
            : MT->translate( "User not found in LDAP: [_1]", $key )
        );
    }

    my ($entry) = $res->entries;
    return $entry;
}

sub get_entry_by_name {
    my $this = shift;
    my ( $name, $attrs ) = @_;
    push @$attrs, 'dn';

    my $cfg            = MT->config;
    my $field_name_uid = $this->uid_attr_name;

    my $filter = $this->{filter};
    if ( $filter eq '' ) {
        $filter = $field_name_uid . '=' . $name;
    }
    else {
        $filter
            = '(&(' . $field_name_uid . '=' . $name . ') ' . $filter . ')';
    }

    my $entry = $this->_get_entry( $filter, $attrs, $name );
    return $entry;
}

sub get_entry_by_uuid {
    my $this = shift;
    my ( $uuid, $attrs ) = @_;

    my $cfg                = MT->config;
    my $id_field_name_ldap = $cfg->LDAPUserIdAttribute
        || $this->ldap->uid_attr_name;

    my $filter = $this->{filter};
    if ( $filter eq '' ) {
        $filter = $id_field_name_ldap . '=' . $uuid;
    }
    else {
        $filter
            = '(&('
            . $id_field_name_ldap . '='
            . $uuid . ') '
            . $filter . ')';
    }

    my $entry = $this->_get_entry( $filter, $attrs, $uuid );
    return $entry;
}

sub get_dn {
    my $this   = shift;
    my ($name) = @_;
    my $entry  = $this->get_entry_by_name($name);
    $entry ? $entry->dn : undef;
}

1;
__END__

=head1 NAME

MT::LDAP

=head1 METHODS

TODO

=head1 AUTHOR & COPYRIGHT

Please see L<MT/AUTHOR & COPYRIGHT>.

=cut
