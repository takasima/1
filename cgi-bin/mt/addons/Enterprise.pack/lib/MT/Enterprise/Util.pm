# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$
package MT::Enterprise::Util;

use strict;
use MT::ObjectDriverFactory;

sub init {
    require MT::Util::DBIRole;
    if ( my $roles = MT->config->DatabaseRoles ) {
        MT::Util::DBIRole->init_from_db_config($roles);
    }
    return 1;
}

sub cfg_database_roles {
    my $mgr = shift;
    return $mgr->set_internal( 'DatabaseRoles', @_ ) if @_;
    my $val = $mgr->get_internal('DatabaseRoles');
    return $val if ref($val) eq 'HASH';
    return $val if !$val || !-f ($val);

    require YAML::Tiny;
    my $y = eval { YAML::Tiny->read($val) }
        or die "Error reading $val: " . ( YAML::Tiny->errstr || $@ || $! );

    # skip over non-hash elements
    shift @$y while @$y && ( ref( $y->[0] ) ne 'HASH' );
    my $roles = $y->[0] if @$y;
    die "Error reading roles in $val" unless ref($roles) eq 'HASH';
    $mgr->set_internal( 'DatabaseRoles', $roles );
    return $roles;
}

# Install a driver_for_factory handler that does role assignment
no warnings 'redefine';
*MT::ObjectDriverFactory::driver_for_class = sub {
    my $pkg = shift;
    my ($class) = @_;
    require MT::ObjectDriver::Driver::CacheWrapper;
    my $driver_code = MT::ObjectDriver::Driver::CacheWrapper->wrap(
        sub {
            my $cfg = MT->config;
            my $role
                = $class
                ? ( $class->properties->{role} || 'global' )
                : 'global';
            my $Password = $cfg->DBPassword;
            my $Username = $cfg->DBUser;
            my $dbd      = $pkg->dbd_class;

            my ( $get_dbh, $reuse_dbh );

            # our handle getter should route through DBIRole, if it
            # is configured; if not, just use the init_db call.
            if ( MT::Util::DBIRole->is_active ) {
                $get_dbh = make_get_dbh($class);
            }
            else {
                $reuse_dbh = 1;
            }

            my $driver = MT::ObjectDriver::Driver::DBI->new(
                role => $role,
                dbd  => $dbd,
                dsn  => $dbd->dsn_from_config($cfg),
                ( $get_dbh   ? ( get_dbh   => $get_dbh )  : () ),
                ( $reuse_dbh ? ( reuse_dbh => 1 )         : () ),
                ( $Username  ? ( username  => $Username ) : () ),
                ( $Password  ? ( password  => $Password ) : () ),
            );
            push @MT::ObjectDriver::Factory::drivers, $driver;
            return $driver;
        },
        $class
    );
    return $driver_code;
};
*MT::ObjectDriverFactory::cleanup = sub {
    if ( my $driver = $MT::Object::DRIVER ) {
        if ( my $dbh = $driver->dbh ) {
            $dbh->disconnect;
            $driver->dbh->{private_set_names} = undef;
            $driver->dbh(undef);
        }
        $MT::Object::DRIVER     = undef;
        $MT::Object::DBI_DRIVER = undef;
    }
    foreach my $driver (@MT::ObjectDriverFactory::drivers) {
        if ( my $dbh = $driver->dbh ) {
            $dbh->disconnect;
            $driver->dbh->{private_set_names} = undef;
            $driver->dbh(undef);
        }
    }
    @MT::ObjectDriverFactory::drivers = ();
    undef $MT::ObjectDriverFactory::DRIVER;
    if ( MT::Util::DBIRole->is_active ) {
        MT::Util::DBIRole->disconnect_all;
    }
};

sub make_get_dbh {
    my ($class) = @_;
    return sub {
        my ($opt) = @_;
        my $driver = $opt->{driver};
        my $role = $driver->role || 'global';
        my $dbh;

        # This bit of logic will remap a slave role request to a
        # non-slave role in the event that a non-slave role was
        # requested in the current request for this same class.
        # This means that if a write is executed for a given class,
        # subsequent reads within the same request will be applied
        # to the same role, rather than to a slave role (which may
        # or may not be up-to-date by that time).
        my $r = MT->request;
        my $role_map;
        unless ( $role_map = $r->cache('dod_class_write_flags') ) {
            $role_map = {};
            $r->cache( 'dod_class_write_flags', $role_map );
        }
        if ( $opt && $opt->{readonly} ) {
            if ( !exists $role_map->{$class} ) {
                $role .= '_slave';
            }
        }
        else {

            # assuming read/write role; flag this class so
            # any subsequent read requests will flow to the
            # non-slave role
            $role_map->{$class} = 1;
        }

        if ( $dbh = MT::Util::DBIRole->connect($role) ) {
            $driver->dbd->init_dbh($dbh)
                unless $dbh->{private_init_dbh};
            $dbh->{private_init_dbh} = 1;
        }

        return $dbh;
    };
}

1;
