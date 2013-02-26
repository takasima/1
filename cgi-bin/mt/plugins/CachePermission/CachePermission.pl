package MT::Plugin::CachePermission;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

our $VERSION = '1.1';
my $plugin = __PACKAGE__->new( {
    name => 'CachePermission',
    id   => 'CachePermission',
    key  => 'cachepermission',
    version => $VERSION,
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => "Cache author's permissions.",
} );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        callbacks => {
            init_app     => \&_init_app,
            init_request => \&_init_request,
        },
    } );
}

MT->add_plugin( $plugin );

sub _init_request {
    my $key = 'permission_cache.' . MT->instance()->cookie_val( 'mt_user' );
    MT->request( $key, undef );
}

sub _init_app {
    require MT::Permission;
    no warnings 'redefine';
    my $original = \&MT::Permission::perms_from_registry;
    *MT::Permission::perms_from_registry = sub {
        unless ( MT->instance()->can( 'cookie_val' ) ) {
            return $original->();
        }
        my $key = 'permission_cache.' . MT->instance()->cookie_val( 'mt_user' );
        my $cache = MT->request( $key );
        if (! $cache ) {
            $cache = $original->();
            MT->request( $key, $cache );
        }
        return $cache;
    };
}

1;
