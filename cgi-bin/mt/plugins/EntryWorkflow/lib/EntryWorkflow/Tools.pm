package EntryWorkflow::Tools;
use strict;

sub converter {
    my @entries = MT::Entry->load( { status => 6, 
                                     class => '*',
                                   }
                                 );
    for my $entry ( @entries ) {
        $entry->status( MT::Entry::REVIEW() );
        $entry->save or die $entry->errstr;
    }
}

1;