# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::Driver::DBD::Oracle;

use strict;
use warnings;

our $BLOB_MAXLEN = 512 * 1024;

use base qw(
    MT::ObjectDriver::Driver::DBD::Legacy
    Data::ObjectDriver::Driver::DBD
    MT::ErrorHandler
);

use DBD::Oracle qw(:ora_types);
use Data::ObjectDriver::Errors;

use constant ERROR_MAP =>
    { 1 => Data::ObjectDriver::Errors->UNIQUE_CONSTRAINT, };

# Oracle has problems with prepare_cached
sub can_prepare_cached_statements { 0 }

sub sql_class {
    require MT::ObjectDriver::SQL::Oracle;
    return 'MT::ObjectDriver::SQL::Oracle';
}

sub ddl_class {
    require MT::ObjectDriver::DDL::Oracle;
    return 'MT::ObjectDriver::DDL::Oracle';
}

sub dsn_from_config {
    my $dbd   = shift;
    my $dsn   = $dbd->SUPER::dsn_from_config(@_);
    my ($cfg) = @_;
    if ( $cfg->DBHost ) {
        $dsn .= ':host=' . $cfg->DBHost;
        $dsn .= ';sid=' . $cfg->Database;
        $dsn .= ';port=' . $cfg->DBPort if $cfg->DBPort;
    }
    else {
        $dsn .= ':' . $cfg->Database;
    }

    return $dsn;
}

{

    sub init_dbh {
        my $dbd = shift;
        my ($dbh) = @_;
        $dbh->{LongReadLen} = $BLOB_MAXLEN;
        $dbh->{LongTruncOk} = 1;
        $dbh->do(
            q{ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'});
        return $dbh;
    }
}

my $orig_search;

sub configure {
    my $dbd = shift;
    my ($driver) = @_;
    $driver->pk_generator( \&pk_generator );
    no warnings 'redefine';

   #
   # Test the $orig_search variable to see if it has already been set with the
   # location of the MT::ObjectDriver::Driver::DBI::search sub, before
   # proceeding to remap MT::ObjectDriver::Driver::DBI::search to the
   # driver_search() sub.
   #
    unless ($orig_search) {
        $orig_search = \&MT::ObjectDriver::Driver::DBI::search;
        *MT::ObjectDriver::Driver::DBI::search = \&driver_search;
    }
    return $dbd;
}

sub bind_param_attributes {
    my ( $dbd, $type, $obj, $field ) = @_;
    my $data_type
        = ref($type) eq 'HASH'
        ? $type->{type}
        : $type;
    if ( $data_type eq 'text' ) {
        return {
            'ora_type'  => ORA_CLOB,
            'ora_field' => $dbd->db_column_name( $obj->datasource, $field )
        };
    }
    if ( $data_type eq 'blob' ) {
        return {
            'ora_type'  => ORA_BLOB,
            'ora_field' => $dbd->db_column_name( $obj->datasource, $field )
        };
    }
    return undef;
}

sub sequence_name {
    my $dbd = shift;
    my ($class) = @_;

    my $key = $class->properties->{primary_key};
    ## If it's a complex primary key, use the second half.
    if ( ref $key ) {
        $key = $key->[1];
    }

    # mt_tablename_columnname
    return join '_', 'mt',
        $dbd->db_column_name( MT::Object->driver->table_for($class), $key );
}

sub fetch_id {
    my $dbd = shift;
    my ( $class, $dbh, $sth ) = @_;
    return $dbh->last_insert_id( undef, undef, undef, undef,
        { sequence => $dbd->sequence_name($class) } );
}

sub pk_generator {
    my ($obj) = @_;
    my $pk = $obj->primary_key_tuple;

    my $is_mt_object = UNIVERSAL::isa( $obj, 'MT::Object' ) ? 1 : 0;
    my $driver
        = $is_mt_object
        ? $obj->driver
        : MT::Object->driver;
    my $dbh       = $driver->rw_handle;
    my $generated = 0;
    for my $col (@$pk) {
        if ( $obj->$col ) {
            ## it's not really generated but need this to trick DOD::DBI
            $generated = $obj->$col;
            next;
        }
        if ($is_mt_object) {
            my $def = $obj->column_def($col);
            next
                unless $def->{type} eq 'integer'
                    || $def->{type} eq 'bigint';
        }
        my $seq = $driver->dbd->sequence_name( ref $obj );
        my $sql = "SELECT $seq.nextval FROM DUAL";
        my $sth
            = $dbh->prepare($sql)
            or die UNIVERSAL::isa( $obj, 'MT::ErrorHandler' )
            ? $obj->error( $dbh->errstr )
            : undef;
        $sth->execute
            or die UNIVERSAL::isa( $obj, 'MT::ErrorHandler' )
            ? $obj->error( $dbh->errstr )
            : undef;
        $sth->bind_columns( undef, \my ($id) );
        $sth->fetch;
        $sth->finish;
        $id = pack 'C0A*', $id;
        $obj->$col($id);
        $generated = $id;
    }
    return $generated;
}

sub map_error_code {
    my $dbd = shift;
    my ( $code, $msg ) = @_;
    return ERROR_MAP->{$code};
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

MT::ObjectDriver::Driver::DBD::Oracle

=head1 METHODS

TODO

=head1 AUTHOR & COPYRIGHT

Please see L<MT/AUTHOR & COPYRIGHT>.

=cut
