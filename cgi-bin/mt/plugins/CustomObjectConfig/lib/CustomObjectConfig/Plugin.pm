package CustomObjectConfig::Plugin;

use strict;

sub initializer {
    require CustomObjectConfig::BackupRestore;
    require CustomObjectConfig::OverRide;
}

1;
