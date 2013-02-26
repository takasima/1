package PowerCMS::CMS;
use strict;

sub _mode_login_error {
    my $app = shift;
    my $plugin = MT->component( 'PowerCMS' );
    my $err = $plugin->translate( 'Permission denied.' );
    if ( $app->param( 'is_locked' ) ) {
        $err = $plugin->translate( "The server is temporarily unable to service your request due to maintenance downtime. <br />Please try again later.
If you think this is a server error, please contact the webmaster." );
    }
    $app->build_page(
        'login.tmpl',
        {   error          => $err,
            no_breadcrumbs => 1,
            login_fields =>
                sub { MT::Auth->login_form($app) },
            can_recover_password =>
                sub { MT::Auth->can_recover_password },
            delegate_auth => sub { MT::Auth->delegate_auth },
        }
        );
}

1;