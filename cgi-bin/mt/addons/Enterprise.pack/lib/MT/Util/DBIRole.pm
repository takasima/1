# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Util::DBIRole;

use strict;
use warnings;

use Carp;

our $DBIRole;
our %Roles;
our $Opts = {};

sub clear_roles {
    %Roles = ();
    undef $DBIRole;
}

sub is_active {
    return ( defined($DBIRole) );
}

sub add_role {
    my $class = shift;

    # xxx support $app namespace?
    my ( $role, $props ) = @_;
    push @{ $Roles{$role} }, $props;
}

sub init {
    my $class = shift;
    my ($opt) = @_;
    $opt ||= {};

    my $sources;
    $Roles{master} ||= $Roles{global};    # xxx hack

    for my $role ( keys %Roles ) {
        my $i = 'a';                      # use magic increment a->b->c
        for my $data ( @{ $Roles{$role} } ) {
            my $this_role = $role . $i++;
            $data->{role} = { $this_role => $data->{weight} || 1 };
            $data->{cache_for} = $data->{cycle} * 60 if exists $data->{cycle};
            $sources->{$this_role} = $data;
        }
    }

    require DBI::Role;
    $DBIRole = DBI::Role->new( { sources => $sources, %$opt } );
}

sub init_from_db_config {
    my $class = shift;
    my ($dbs) = @_;

    require List::Util;

    ## Load the role-to-DSN mapping information into DBI::Role.
    $class->clear_roles;
    my $attr = {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    };

    # A MT DatabaseRole structure looks like this:
    # global:
    #     password: foo
    #     host: xxx
    #     slaves:
    #         - host: abc1
    #         - host: abc2
    #
    # would define a 'blog1' partition (to be used in a later release)
    # blog1:
    #     host: xxx
    #     slaves:
    #         - host: yyy

    my $defaults = {};
    my $cfg      = MT->config;
    $defaults->{dbname} = $cfg->Database;
    $defaults->{user}   = $cfg->DBUser;
    $defaults->{pass}   = $cfg->DBPassword;
    $defaults->{host}   = $cfg->DBHost;
    $defaults->{port}   = $cfg->DBPort;
    $defaults->{sock}   = $cfg->DBSocket;

    require MT::ObjectDriverFactory;
    my $dbd_class_pkg = MT::ObjectDriverFactory->dbd_class;
    my $dbd_class     = $dbd_class_pkg;
    $dbd_class =~ s/.+:://;
    $defaults->{driver} = $dbd_class;

    my $dsn_maker = sub {
        $dbd_class_pkg->dsn_from_config( _ProfileConfig->new(@_) );
    };

    # assign over 'DB*' defaults if a 'defaults'
    # key is present in role list (but 'defaults' is not a valid role)
    if ( ref( my $def = $dbs->{defaults} ) eq 'HASH' ) {
        $defaults->{$_} = $def->{$_} for keys %$def;
    }

    for my $role ( keys %$dbs ) {
        next if $role eq 'defaults';

        my %props = %$defaults;

        my $role_def = $dbs->{$role};
        next unless ref $role_def eq 'HASH';

        foreach ( keys %$role_def ) {
            $props{$_} = $role_def->{$_} if !ref $role_def->{$_};
        }
        $class->add_role( $role, \%props );

        if ( ref( my $slaves = $role_def->{slaves} ) eq 'ARRAY' ) {
            foreach my $slave_def (@$slaves) {
                next unless ref $slave_def eq 'HASH';

                my %slave_props = %props;
                foreach ( keys %$slave_def ) {
                    $slave_props{$_} = $slave_def->{$_}
                        if !ref $slave_def->{$_};
                }
                $class->add_role( $role . '_slave', \%slave_props );
            }
        }
    }
    if ( $cfg->DBCheckSlaveStatus ) {
        $Opts->{check_slave_status} = 1;
        if ( $cfg->DBMaxReplicationLag ) {
            $Opts->{max_repl_lag} = $cfg->DBMaxReplicationLag;
        }
    }
    my $retry = $cfg->DBRetryDuration;
    $class->init(
        {   make_dsn => $dsn_maker,
            ( $retry ? ( retry_duration => $retry ) : () )
        }
    );
}

sub connect {
    my $class = shift;
    if ( !$DBIRole ) {

        # failsafe; but this should never be called if we're not using roles
        return MT::Object->driver->rw_handle;
    }

    my ($role) = @_;
    my @want_roles = want_roles($role);

    if ( !@want_roles && ( $role =~ m/_slave$/ ) ) {

        # try for a non-slave role if no slaves were found
        $role =~ s/_slave$//;
        @want_roles = want_roles($role);
    }

    if ( scalar @want_roles > 0 ) {
        @want_roles = List::Util::shuffle(@want_roles);
    }

    my $dbh = $DBIRole->get_dbh( $Opts, @want_roles );
    unless ($dbh) {
        if ( $role =~ m/_slave$/ ) {
            $role =~ s/_slave$//;
            @want_roles = want_roles($role);
            $dbh = $DBIRole->get_dbh( $Opts, @want_roles );
        }
    }

    unless ($dbh) {
        die "Unable to get dbh for role '$role'. "
            . "'$DBI::errstr' ($DBI::err)";
    }

    return $dbh;
}

sub want_roles {
    my $role = shift;

    my $i = 'a';
    return map $role . $i++, 0 .. $#{ $Roles{$role} };
}

sub disconnect_all {
    my $class = shift;
    $DBIRole->disconnect_all;
}

sub clear_req_cache {
    $DBIRole->clear_req_cache;
}

package _ProfileConfig;

use base qw( MT::ConfigMgr );

sub new {
    my $class  = shift;
    my $mgr    = $class->SUPER::new();
    my ($info) = @_;
    foreach (qw( pass host port sock user dbname )) {
        $mgr->set( $_, $info->{$_} ) if exists $info->{$_};
    }
    return $mgr;
}

sub init {
    my $mgr = shift;
    $mgr->define(
        {   Database       => undef,
            dbname         => { alias => 'Database' },
            DBSocket       => undef,
            sock           => { alias => 'DBSocket' },
            DBPassword     => undef,
            pass           => { alias => 'DBPassword' },
            DBUser         => undef,
            user           => { alias => 'DBUser' },
            DBPort         => undef,
            port           => { alias => 'DBPort' },
            DBHost         => undef,
            host           => { alias => 'DBHost' },
            PublishCharset => {
                handler => sub { return MT->config->PublishCharset }
            },
        }
    );
}

1;
