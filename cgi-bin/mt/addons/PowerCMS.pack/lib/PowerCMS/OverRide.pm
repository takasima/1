package PowerCMS::OverRide; # Literal error for "Override"
use strict;

sub init {
    # Only for override.
    # Do nothing.
}

no warnings 'redefine';
require MT::Mail;
*MT::Mail::_send_mt_sendmail = sub {
    # PATCH
    use MT::Util qw( is_valid_email );
    my @Sendmail
        = qw( /usr/lib/sendmail /usr/sbin/sendmail /usr/ucblib/sendmail );
    # /PATCH

    my $class = shift;
    my ( $hdrs, $body, $mgr ) = @_;
    $hdrs->{To} = $mgr->DebugEmailAddress
        if ( is_valid_email( $mgr->DebugEmailAddress || '' ) );
    my $sm_loc;
    for my $loc ( $mgr->SendMailPath, @Sendmail ) {
        next unless $loc;
        $sm_loc = $loc, last if -x $loc && !-d $loc;
    }
    return $class->error(
        MT->translate(
                  "You do not have a valid path to sendmail on your machine. "
                . "Perhaps you should try using SMTP?"
        )
    ) unless $sm_loc;
    local $SIG{PIPE} = {};
    my $pid = open MAIL, '|-';
    local $SIG{ALRM} = sub { CORE::exit() };
    return unless defined $pid;
    if ( !$pid ) {
    # PATCH
if ( MT->config->MailReturnPath && is_valid_email( MT->config->MailReturnPath ) ) {
        exec $sm_loc, "-oi", "-t", ( '-f' . MT->config->MailReturnPath ),
            or return $class->error(
            MT->translate( "Exec of sendmail failed: [_1]", "$!" ) );
} else {
        exec $sm_loc, "-oi", "-t"
            or return $class->error(
            MT->translate( "Exec of sendmail failed: [_1]", "$!" ) );
}
    # /PATCH
    }
    for my $key ( keys %$hdrs ) {
        my @arr
            = ref( $hdrs->{$key} ) eq 'ARRAY'
            ? @{ $hdrs->{$key} }
            : ( $hdrs->{$key} );
        print MAIL map "$key: $_\n", @arr;
    }
    print MAIL "\n";
    print MAIL $body;
    close MAIL;
    1;
};

1;
