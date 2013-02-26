# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::Driver::DBD::MSSQLServer;

use strict;
use warnings;

use base qw(
    MT::ObjectDriver::Driver::DBD::Legacy
    Data::ObjectDriver::Driver::DBD
    MT::ErrorHandler
);

use DBI qw(:sql_types);
use Data::ObjectDriver::Errors;
use MT::ObjectDriver::SQL::MSSQLServer;

use constant ERROR_MAP =>
    { 1 => Data::ObjectDriver::Errors->UNIQUE_CONSTRAINT, };

our $BLOB_MAXLEN       = 512 * 1024;
our %SUPPORTED_CHARSET = (
    'iso-8859-1' => 1,
    'shift_jis'  => 1,
);

sub sql_class {
    require MT::ObjectDriver::SQL::MSSQLServer;
    return 'MT::ObjectDriver::SQL::MSSQLServer';
}

sub ddl_class {
    require MT::ObjectDriver::DDL::MSSQLServer;
    return 'MT::ObjectDriver::DDL::MSSQLServer';
}

sub dsn_from_config {
    my $dbd = shift;
    my ($cfg) = @_;
    if ( !exists $SUPPORTED_CHARSET{ lc( $cfg->PublishCharset ) } ) {
        die MT->translate(
            'PublishCharset [_1] is not supported in this version of the MS SQL Server Driver.',
            $cfg->PublishCharset
        );
    }
    my $dsn = 'dbi:ODBC:Driver={' . $cfg->ODBCDriver . '}';
    if ( $cfg->DBHost ) {
        $dsn .= ';Server=' . $cfg->DBHost;
        $dsn .= ',' . $cfg->DBPort if $cfg->DBPort;
    }
    $dsn .= ';Database=' . $cfg->Database;
    if ( $cfg->DBUser && $cfg->DBPassword ) {
        $dsn .= ';UID=' . $cfg->DBUser;
        $dsn .= ';PWD=' . $cfg->DBPassword;
    }
    else {
        $dsn .= ';Trusted_Connection=Yes';    #Integrated Security=SSPI';
    }
    $dsn .= ';Mars_Connection=yes';
    return $dsn;
}

sub init_dbh {
    my $dbd = shift;
    my ($dbh) = @_;

    #    $dbh->{odbc_exec_direct} = 1;
    $dbh->{LongReadLen} = $BLOB_MAXLEN;
    $dbh->{LongTruncOk} = 1;
    no warnings 'redefine';

    # replace ping method because DBD::ODBC::db::ping is
    # too inefficient.  BugId:81797
    *DBD::ODBC::db::ping = \&_ping;

    $dbh;
}

sub _ping {
    my $dbh = shift;
    return 0 unless $dbh;
    eval {

        # this does talk to the server
        $dbh->do('SELECT @@VERSION');
    };
    return $@ ? 0 : 1;
}

sub ts2db {
    return unless $_[1] =~ m/^\d{14}(?:[\.|:]\d{3})?$/;
    sprintf '%04d-%02d-%02d %02d:%02d:%02d', unpack 'A4A2A2A2A2A2', $_[1];
}

sub db2ts {
    ( my $ts = $_[1] ) =~ tr/\- ://d;
    $ts =~ s/^(\d{14})[\.|:]\d{3}?$/$1/;
    return 0 if defined $ts && $ts eq '00000000000000';
    $ts;
}

sub bind_param_attributes {
    my ( $dbd, $type ) = @_;
    my $data_type = ref($type) ? $type->{type} : $type;
    if ( $data_type eq 'text' ) {

        #return SQL_WLONGVARCHAR;
        return SQL_LONGVARCHAR;
    }
    elsif ( $data_type eq 'blob' ) {
        return SQL_LONGVARBINARY;
    }
    return undef;
}

sub fetch_id {
    my $dbd = shift;
    my ( $class, $dbh, $sth ) = @_;
    my $sql
        = 'select IDENT_CURRENT(\''
        . MT::Object->driver->table_for($class)
        . '\') AS ID';
    my $sth2 = $dbh->prepare_cached($sql);
    $sth2->execute();
    my $id = $sth2->fetch;
    $sth2->finish;
    $id->[0];
}

sub map_error_code {
    my $dbd = shift;
    my ( $code, $msg ) = @_;
    return ERROR_MAP->{$code};
}

my $orig_search;
my $insert_triggers_installed;

sub configure {
    my $dbd = shift;
    my ($driver) = @_;
    no warnings 'redefine';
    *MT::ObjectDriver::Driver::DBI::count = \&count;
    $orig_search = \&MT::ObjectDriver::Driver::DBI::search;
    *MT::ObjectDriver::Driver::DBI::search = \&driver_search;
    unless ($insert_triggers_installed) {
        require MT::Object;
        MT::Object->add_trigger( 'pre_insert'  => \&pre_insert );
        MT::Object->add_trigger( 'post_insert' => \&post_insert );
        $insert_triggers_installed = 1;
    }

    $driver->rw_handle->{odbc_err_handler} = \&msg_handler;
    return $dbd;
}

sub msg_handler {
    my ( $state, $msg, $h ) = @_;

    require MT::I18N;
    my $enc = MT::I18N::guess_encoding($msg);
    $msg = Encode::decode( $enc, $msg );
    die $msg;
}

sub count {
    my $driver = shift;
    my ( $class, $terms, $args ) = @_;

    my @joins = ( $args->{join}, @{ $args->{joins} || [] } );
    my $select = 'COUNT(*)';
    for my $join (@joins) {
        if ( $join && $join->[3]->{unique} ) {
            my $col;
            if ( $join->[3]{unique} =~ m/\D/ ) {
                $col = $args->{join}[3]{unique};
            }
            else {
                $col = $class->properties->{primary_key};
            }
            my $dbcol
                = $driver->dbd->db_column_name( $class->datasource, $col );
            ## the lines below is the only difference from the DBI::count method.
            $select = "COUNT(DISTINCT $dbcol)";
            $args->{count_distinct} = { $col => 1 };
        }
    }

    my $result = $driver->_select_aggregate(
        select   => $select,
        class    => $class,
        terms    => $terms,
        args     => $args,
        override => {
            order  => '',
            limit  => undef,
            offset => undef,
        },
    );
    delete $args->{count_distinct};
    $result;
}

sub _insert_trigger {
    my ( $obj, $orig_obj, $flag ) = @_;
    my $pk = $obj->properties->{primary_key};
    if (   $pk
        && !ref($pk)
        && $obj->$pk
        && $obj->column_def($pk)->{auto} )
    {
        my $dbh   = $obj->driver->rw_handle;
        my $table = $obj->table_name;
        $dbh->do("SET IDENTITY_INSERT $table $flag");
    }
    1;
}

sub pre_insert {
    _insert_trigger( @_, 'ON' );
}

sub post_insert {
    _insert_trigger( @_, 'OFF' );
}

sub driver_search {
    my $driver = shift;
    my ( $class, $terms, $args ) = @_;
    my @joins = (
        ( $args->{join}  ? $args->{join}       : () ),
        ( $args->{joins} ? @{ $args->{joins} } : () ),
    );
    my $need_unique;
    foreach (@joins) {
        $need_unique = 1, last if $_->[3]->{unique};
    }

    if (wantarray) {
        if ( $need_unique
            && ( my $lob_columns = $class->columns_of_type( 'text', 'blob' ) )
            )
        {
            my @objs = $orig_search->( $driver, @_ );
            my %dupe;
            @objs = grep { !$dupe{ $_->id }++ } @objs;
            return @objs;
        }
    }
    else {
        if ($need_unique) {
            my $result = $orig_search->( $driver, @_ );
            return $result
                if 'CODE' ne ref($result)
                    && 'Data::ObjectDriver::Iterator' ne ref($result);
            my %dupe;
            my $iter = sub {
                my $tmp = $result->();
                return unless defined $tmp;
                while ( exists $dupe{ $tmp->id } ) {
                    $tmp = $result->();
                    return unless defined $tmp;
                }
                $dupe{ $tmp->id } = 1;
                $tmp;
            };
            return $iter if 'CODE' eq ref($result);
            return Data::ObjectDriver::Iterator->new( $iter,
                sub { $result->end(@_) } );
        }
    }
    return $orig_search->( $driver, @_ );
}

1;
__END__

=head1 NAME

MT::ObjectDriver::Driver::DBD::MSSQLServer

=head1 METHODS

TODO

=head1 AUTHOR & COPYRIGHT

Please see L<MT/AUTHOR & COPYRIGHT>.

=cut
