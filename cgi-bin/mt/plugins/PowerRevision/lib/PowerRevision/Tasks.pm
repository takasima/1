package PowerRevision::Tasks;
use strict;

use PowerRevision::Util;
use PowerRevision::Plugin;

my $plugin = MT->component( 'PowerRevision' );

sub _task_cleanup_assets {
    PowerRevision::Util::cleanup_assets();
}

sub _task_scheduled_post {
    my $app = MT->instance();
    my @blogs = MT::Blog->load( { class => '*' } );
    for my $blog ( @blogs ) {
        PowerRevision::Util::change_status( $app, $blog, 1 );
    }
    return 1;
}

1;