#!/usr/bin/env perl -w

use strict;
use Test::More tests => 1;

use WWW::SourceForge::Project;

# Can I assume that there is no such project ?
my $sfp = WWW::SourceForge::Project->new('zzzzzzzz');

is( $sfp , undef );

