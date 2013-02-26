#!/usr/bin/perl -w

use strict;
use lib $ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : 'lib';
use lib 'addons/ContactForm.pack/lib';

use MT::Bootstrap App => 'MT::App::ContactForm';