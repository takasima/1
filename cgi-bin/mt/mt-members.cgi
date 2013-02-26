#!/usr/bin/perl -w

use strict;

use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : 'lib';

use lib $ENV{MT_HOME}
    ? "$ENV{MT_HOME}addons/PowerCMS.pack/lib"
    : 'addons/PowerCMS.pack/lib';

use lib $ENV{MT_HOME}
    ? "$ENV{MT_HOME}plugins/Members/lib"
    : 'plugins/Members/lib';

use MT::Bootstrap App => 'MT::App::CMS::Members';
