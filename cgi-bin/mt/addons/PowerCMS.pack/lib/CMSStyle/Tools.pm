package CMSStyle::Tools;
use strict;

sub _task_clean_markupvalidation_data {
    my @sessions = MT->model( 'session' )->load( { kind => 'MV',
                                                   start => [ undef, time - 60 * 60 ],
                                                 }, {
                                                   range => { start => 1 },
                                                 }
                                               );
    foreach my $session ( @sessions ) {
        $session->remove;
    }
    return '';
}

1;