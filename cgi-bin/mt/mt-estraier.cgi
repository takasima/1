#!/usr/bin/perl -w

use strict;
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : 'lib';

use lib qw( addons/PowerCMS.pack/lib );
use lib qw( plugins/PowerSearch/lib );

use MT::Bootstrap App => 'MT::App::CMS::SearchEstraier';
