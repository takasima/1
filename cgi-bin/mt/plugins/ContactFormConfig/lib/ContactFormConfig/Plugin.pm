package ContactFormConfig::Plugin;

use strict;

sub _post_run {
    my $app = MT->instance();
    my $install = 0;
    if ( ( ref $app ) eq 'MT::App::Upgrader' ) {
        if ( $app->mode eq 'run_actions' ) {
            if ( $app->param( 'installing' ) ) {
                $install++;
            }
        }
    } elsif (! $app->blog ) {
        if ( $app->mode eq 'reset_plugin_config' ) {
            if ( $app->param( 'plugin_sig' ) eq 'ContactFormConfig' ) {
                if ( $app->validate_magic ) {
                    $install++;
                }
            }
        }
    }
    if ( $install ) {
        require ContactFormConfig::Upgrade;
        ContactFormConfig::Upgrade::_upgrade_functions();
    }
    return 1;
}

# sub _create_new_blog {
#     my ( $cb, $app, $obj, $original ) = @_;
#     if ( defined $original && (! $original->id ) ) {
#         require ContactFormConfig::Upgrade;
#         ContactFormConfig::Upgrade::_upgrade_functions( 'new_blog', $obj );
#     }
#     return 1;
# }

1;
