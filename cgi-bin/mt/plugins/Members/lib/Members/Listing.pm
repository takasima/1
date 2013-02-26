package Members::Listing;

use strict;
use warnings;

sub system_filters {
    my $filters = {
        members => {
            label => 'Members',
            items => sub {
                [ { filter_key => 'members' } ];
            },
            order => 400,
        },
    };
    return $filters;
}

1;
