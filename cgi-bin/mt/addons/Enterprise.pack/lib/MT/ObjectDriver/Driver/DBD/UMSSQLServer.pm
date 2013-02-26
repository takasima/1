# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::ObjectDriver::Driver::DBD::UMSSQLServer;

use strict;
use warnings;

use base qw( MT::ObjectDriver::Driver::DBD::MSSQLServer );
use DBI qw(:sql_types);

sub ddl_class {
    require MT::ObjectDriver::DDL::UMSSQLServer;
    return 'MT::ObjectDriver::DDL::UMSSQLServer';
}

sub dsn_from_config {
    my $dbd = shift;
    my ($cfg) = @_;

    eval "use DBD::ODBC 1.14;";
    if ($@) {
        die MT->translate(
            'This version of UMSSQLServer driver requires DBD::ODBC version 1.14.'
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

sub bind_param_attributes {
    my ( $dbd, $type ) = @_;
    my $data_type = ref($type) ? $type->{type} : $type;
    if ( $data_type eq 'blob' ) {
        return SQL_LONGVARBINARY;
    }
    return undef;
}

my $post_load_installed;

sub configure {
    my $dbd = shift;
    my ($driver) = @_;
    unless ( exists $driver->rw_handle->{odbc_has_unicode}
        && $driver->rw_handle->{odbc_has_unicode} )
    {
        die MT->translate(
            'This version of UMSSQLServer driver requires DBD::ODBC compiled with Unicode support.'
        );
    }
    $dbd = $dbd->SUPER::configure(@_);
    $dbd;
}

sub need_encode { 0; }
1;
