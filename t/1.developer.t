#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;

use WWW::SourceForge::Project;

my $sfp = WWW::SourceForge::Project->new('chewingosx');

my $members = $sfp->Member;

ok( $members->{'No specific role'}[0]{loginName} eq 'clkao');
ok( $members->{'Project Manager'}[0]{loginName} eq 'gugod');
