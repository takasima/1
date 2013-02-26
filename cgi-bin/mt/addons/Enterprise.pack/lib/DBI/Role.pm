# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package DBI::Role;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';
use Time::HiRes ();

# the default idle timeout for any database connections
sub CONNECTION_TIMEOUT () {300}    # 5 minutes
sub RETRY_DURATION ()     {5}

# $self contains:
#
#  DBINFO --- hashref.  keys = scalar roles, one of which must be 'master'.
#             values contain DSN info, and 'role' => { 'role' => weight, 'role2' => weight }
#
#  DEFAULT_DB -- scalar string.  default db name if none in DSN hashref in DBINFO
#
#  DBREQCACHE -- cleared by clear_req_cache() on each request.
#                fdsn -> dbh
#
#  DBCACHE -- role -> fdsn, or
#             fdsn -> dbh
#
#  DBCACHE_UNTIL -- role -> unixtime
#
#  DB_USED_AT -- fdsn -> unixtime
#
#  DB_DEAD_UNTIL -- fdsn -> unixtime
#
#  TIME_CHECK -- if true, time between localhost and db are checked every TIME_CHECK
#                seconds
#
#  TIME_REPORT -- coderef to pass dsn and dbtime to after a TIME_CHECK occurence
#  MAKE_DSN    -- coderef to pass a db source and translate into a DSN

sub new {
    my ( $class, $args ) = @_;
    my $self = {};
    $self->{'DBINFO'}         = $args->{'sources'};
    $self->{'TIMEOUT'}        = $args->{'timeout'};
    $self->{'DEFAULT_DB'}     = $args->{'default_db'};
    $self->{'TIME_CHECK'}     = $args->{'time_check'};
    $self->{'RETRY_DURATION'} = $args->{'retry_duration'} || RETRY_DURATION;
    $self->{'TIME_LASTCHECK'} = {};    # dsn -> last check time
    $self->{'TIME_REPORT'}
        = $args->{'time_report'};      # currently, mysql-specific
    $self->{'MAKE_DSN'} = $args->{'make_dsn'};
    bless $self, ref $class || $class;
    return $self;
}

sub set_sources {
    my ( $self, $newval ) = @_;
    $self->{'DBINFO'} = $newval;
    $self;
}

sub clear_req_cache {
    my $self = shift;
    $self->{'DBREQCACHE'} = {};
}

sub disconnect_all {
    my ( $self, $opts ) = @_;
    my %except;

    if (   $opts
        && $opts->{except}
        && ref $opts->{except} eq 'ARRAY' )
    {
        $except{$_} = 1 foreach @{ $opts->{except} };
    }

    foreach my $cache (qw( DBREQCACHE DBCACHE )) {
        next unless ref $self->{$cache} eq "HASH";
        foreach my $key ( keys %{ $self->{$cache} } ) {
            next if $except{$key};
            my $v = $self->{$cache}->{$key};
            next unless ref $v eq "DBI::db";
            $v->disconnect;
            delete $self->{$cache}->{$key};
        }
    }
    $self->{'DBCACHE'}    = {};
    $self->{'DBREQCACHE'} = {};
}

sub same_cached_handle {
    my $self = shift;
    my ( $role_a, $role_b ) = @_;
    return
           defined $self->{'DBCACHE'}->{$role_a}
        && defined $self->{'DBCACHE'}->{$role_b}
        && $self->{'DBCACHE'}->{$role_a} eq $self->{'DBCACHE'}->{$role_b};
}

sub flush_cache {
    my $self = shift;
    foreach ( keys %{ $self->{'DBCACHE'} } ) {
        my $v = $self->{'DBCACHE'}->{$_};
        next unless ref $v;
        $v->disconnect;
    }
    $self->{'DBCACHE'}    = {};
    $self->{'DBREQCACHE'} = {};
}

# old interface.  does nothing now.
sub trigger_weight_reload {
    my $self = shift;
    return $self;
}

sub use_diff_db {
    my $self = shift;
    my ( $role1, $role2 ) = @_;

    return 0 if $role1 eq $role2;

    # this is implied:  (makes logic below more readable by forcing it)
    $self->{'DBINFO'}->{'master'}->{'role'}->{'master'} = 1;

    foreach ( keys %{ $self->{'DBINFO'} } ) {
        next if /^_/;
        next unless ref $self->{'DBINFO'}->{$_} eq "HASH";
        if (   $self->{'DBINFO'}->{$_}->{'role'}->{$role1}
            && $self->{'DBINFO'}->{$_}->{'role'}->{$role2} )
        {
            return 0;
        }
    }
    return 1;
}

sub get_dbh {
    my $self = shift;
    my $opts = ref $_[0] eq "HASH" ? shift : {};

    my @roles = @_;
    my $role  = shift @roles;
    return undef unless $role;

    my $now = time();

    # if 'nocache' flag is passed, clear caches now so we won't return
    # a cached database handle later
    $self->clear_req_cache if $opts->{'nocache'};

    # otherwise, see if we have a role -> full DSN mapping already
    my ( $fdsn, $dbh );
    if ( $role eq "master" ) {
        $fdsn = make_dbh_fdsn( $self, $self->{'DBINFO'}->{'master'} );
    }
    else {
        if ( $self->{'DBCACHE'}->{$role} && !$opts->{'unshared'} ) {
            $fdsn = $self->{'DBCACHE'}->{$role};
            if ( $now > $self->{'DBCACHE_UNTIL'}->{$role} ) {

                # we have do delete the entries here or the handle
                # isn't actually freed
                delete $self->{'DBCACHE'}->{$fdsn};
                delete $self->{'DBREQCACHE'}->{$fdsn};

                # this role -> DSN mapping is too old.  invalidate,
                # and while we're at it, clean up any connections we have
                # that are too idle.
                undef $fdsn;

                foreach ( keys %{ $self->{'DB_USED_AT'} } ) {

                    # skip any connections used within the last minute
                    next
                        if $self->{'DB_USED_AT'}->{$_}
                            > $now - CONNECTION_TIMEOUT;
                    delete $self->{'DB_USED_AT'}->{$_};
                    delete $self->{'DBCACHE'}->{$_};
                }
            }
        }
    }

    if ($fdsn) {
        $dbh = get_dbh_conn( $self, $fdsn, $role );
        return $dbh if $dbh;
        delete $self->{'DBCACHE'}->{$role};    # guess it was bogus
    }
    return undef if $role eq "master";         # no hope now

    # time to randomly weightedly select one.
    my @applicable;
    my $total_weight;
    foreach ( keys %{ $self->{'DBINFO'} } ) {
        next if /^_/;
        next unless ref $self->{'DBINFO'}->{$_} eq "HASH";
        my $weight = $self->{'DBINFO'}->{$_}->{'role'}->{$role};
        next unless $weight;
        push @applicable, [ $self->{'DBINFO'}->{$_}, $weight ];
        $total_weight += $weight;
    }

    while (@applicable) {
        my $rand = rand($total_weight);
        my ( $i, $t ) = ( 0, 0 );
        for ( ; $i < @applicable; $i++ ) {
            $t += $applicable[$i]->[1];
            last if $t > $rand;
        }
        my $fdsn = make_dbh_fdsn( $self, $applicable[$i]->[0] );
        my $cycle = $applicable[$i]->[0]->{cache_for}
            || ( 5 + int( rand(10) ) );
        $dbh = get_dbh_conn( $self, $opts, $fdsn, $role );
        if ($dbh) {
            $self->{'DBCACHE'}->{$role}       = $fdsn;
            $self->{'DBCACHE_UNTIL'}->{$role} = $now + $cycle;
            return $dbh;
        }

        # otherwise, discard that one.
        $total_weight -= $applicable[$i]->[1];
        splice( @applicable, $i, 1 );
    }

    # try others
    return get_dbh( $self, $opts, @roles );
}

sub make_dbh_fdsn {
    my $self = shift;
    my $db   = shift;    # hashref with DSN info
    return $db->{'_fdsn'} if $db->{'_fdsn'};    # already made?

    $db->{'dbname'} ||= $self->{'DEFAULT_DB'} if $self->{'DEFAULT_DB'};

    my $fdsn;
    if ( $self->{'MAKE_DSN'} ) {

        # a coderef is available to construct the DSN, so use it
        $fdsn = $self->{'MAKE_DSN'}->($db);
    }
    else {
        $fdsn = "DBI:$db->{'driver'}"
            ;    # join("|",$dsn,$user,$pass) (because no refs as hash keys)
        $fdsn .= ":$db->{'dbname'}";
        $fdsn .= ";host=$db->{'host'}" if $db->{'host'};
        $fdsn .= ";port=$db->{'port'}" if $db->{'port'};
        $fdsn .= ";mysql_socket=$db->{'sock'}" if $db->{'sock'};
        $fdsn .= ';auto_reconnect=1'
            if $db->{'auto_reconnect'} && $db->{'driver'} eq 'mysql';
    }

    # append user/pass, unless '|' exists, which means username/password
    # were already appended, presumably
    $fdsn = join( '|', $fdsn, $db->{'user'} || '', $db->{'pass'} || '' )
        unless $fdsn =~ m/\|/;

    $db->{'_fdsn'} = $fdsn;
    return $fdsn;
}

sub get_dbh_conn {
    my $self = shift;
    my $opts = ref $_[0] eq "HASH" ? shift : {};
    my $fdsn = shift;
    my $role = shift;                              # optional.
    my $now  = time();

    my $retdb = sub {
        my $db = shift;
        $self->{'DBREQCACHE'}->{$fdsn} = $db;
        $self->{'DB_USED_AT'}->{$fdsn} = $now;
        return $db;
    };

    # have we already created or verified a handle this request for this DSN?
    return $retdb->( $self->{'DBREQCACHE'}->{$fdsn} )
        if $self->{'DBREQCACHE'}->{$fdsn} && !$opts->{'unshared'};

    # check to see if we recently tried to connect to that dead server
    return undef
        if $self->{'DB_DEAD_UNTIL'}->{$fdsn}
            && $now < $self->{'DB_DEAD_UNTIL'}->{$fdsn};

    # if not, we'll try to find one we used sometime in this process lifetime
    my $dbh = $self->{'DBCACHE'}->{$fdsn};

    # if it exists, verify it's still alive and return it.  (but not
    # if we're wanting an unshared connection)
    if ( $dbh && !$opts->{'unshared'} ) {
        return $retdb->($dbh) unless connection_bad( $dbh, $opts );
        undef $dbh;
        undef $self->{'DBCACHE'}->{$fdsn};
    }

    # time to make one!
    my ( $dsn, $user, $pass ) = split( /\|/, $fdsn );
    my $timeout = $self->{'TIMEOUT'} || 2;

    # TBD: mysql-specific; although conditioned for mysql in a way
    $dsn .= ";mysql_connect_timeout=$timeout" if $dsn =~ /mysql/i;

    my $try = 0;
    my $tries = $DBI::Role::T_CONNECT_TRIES || 10;
    while (1) {
        my @arg = (
            $dsn, $user, $pass,
            {   PrintError => 0,
                RaiseError => 0,
                AutoCommit => 1,
            }
        );
        $dbh
            = $DBI::Role::T_DBI_CONNECT
            ? $DBI::Role::T_DBI_CONNECT->(@arg)
            : DBI->connect(@arg);
        last if $dbh || $try++ >= $tries;

        warn "Got $DBI::err connecting to $dsn on try $try, retrying";
        Time::HiRes::usleep( $try * 100_000 );
    }

    my $DBI_err = $DBI::err || 0;

    # check replication/busy processes... see if we should not use
    # this one
    # TBD: mysql-specific, although conditioned
    undef $dbh if $fdsn =~ /mysql/i && connection_bad( $dbh, $opts );

    if ($dbh) {

        # reset the RaiseError and stuff passed from caller
        my $passed_attr = $self->{DBINFO}->{$role}->{attr} || {};
        for my $attr (qw( RaiseError PrintError AutoCommit )) {
            if ( defined $passed_attr->{$attr} ) {
                $dbh->{$attr} = $passed_attr->{$attr};
            }
        }
    }

    # if this is an unshared connection, we don't want to put it
    # in the cache for somebody else to use later. (which happens below)
    return $dbh if $opts->{'unshared'};

   # mark server as dead if dead.  won't try to reconnect again for 5 seconds.
    if ($dbh) {
        $self->{'DB_USED_AT'}->{$fdsn} = $now;

        if ( $self->{'TIME_CHECK'} && ref $self->{'TIME_REPORT'} eq "CODE" ) {
            my $now = time();
            $self->{'TIME_LASTCHECK'}->{$dsn} ||= 0;    # avoid warnings
            if ( $self->{'TIME_LASTCHECK'}->{$dsn}
                < $now - $self->{'TIME_CHECK'} )
            {
                $self->{'TIME_LASTCHECK'}->{$dsn} = $now;

                # TBD: this is mysql-specific
                my $db_time
                    = $dbh->selectrow_array("SELECT UNIX_TIMESTAMP()");
                $self->{'TIME_REPORT'}->( $dsn, $db_time, $now );
            }
        }
    }
    else {

# mark the database as dead for a bit, unless it was just because of max connections
        $self->{'DB_DEAD_UNTIL'}->{$fdsn} = $now + $self->{'RETRY_DURATION'}
            unless $DBI_err == 1040;
    }

    return $self->{'DBREQCACHE'}->{$fdsn} = $self->{'DBCACHE'}->{$fdsn}
        = $dbh;
}

# TBD: this is very mysql-specific right now
sub connection_bad {
    my ( $dbh, $opts ) = @_;

    return 1 unless $dbh;

    return 0 unless $opts->{check_slave_status};

    my $ss = eval { $dbh->selectrow_hashref("SHOW SLAVE STATUS"); };

    # if there was an error, and it wasn't a permission problem (1227)
    # then treat this connection as bogus
    if ( $dbh->err && $dbh->err != 1227 ) {
        return 1;
    }

    # connection is good if $ss is undef (not a slave)
    return 0 unless $ss;

    # otherwise, it's okay if not MySQL 4
    return 0 if !$ss->{'Master_Log_File'} || !$ss->{'Relay_Master_Log_File'};

    # all good if within 100 k
    if ( $opts->{'max_repl_lag'} ) {
        return 0
            if $ss->{'Master_Log_File'} eq $ss->{'Relay_Master_Log_File'}
                && (  $ss->{'Read_Master_Log_Pos'}
                    - $ss->{'Exec_Master_Log_Pos'} )
                < $opts->{'max_repl_lag'};

        # guess we're behind
        return 1;
    }
    else {

        # default to assuming it's good
        return 0;
    }
}

1;
__END__

=head1 NAME

DBI::Role - Get DBI cached handles by role, with weighting & failover.

=head1 SYNOPSIS

  use DBI::Role;
  my $DBIRole = new DBI::Role {
    'sources' => \%DBINFO,
    'default_db' => "somedbname", # opt.
  };
  my $dbh = $DBIRole->get_dbh("master");

=head1 DESCRIPTION

To be written.

=head2 EXPORT

None by default.

=head1 AUTHOR

Brad Fitzparick, E<lt>brad@danga.comE<gt>

=head1 SEE ALSO

L<DBI>.
