package EntryUnpublish::Task;
use strict;

use EntryUnpublish::Util;

sub _unpublish_task {
    my $app = MT->instance();
    my @blogs = MT::Blog->load( { class => '*' } );
    my @titles;
    for my $blog ( @blogs ) {
        push ( @titles, EntryUnpublish::Util::change_status( $app, $blog ) );
    }
    return 1;
}

1;