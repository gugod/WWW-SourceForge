#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 1;

use WWW::SourceForge::Project;

my $sfp = WWW::SourceForge::Project->new('a-peer');

my $members = $sfp->Member;

for(values %$members) {
    print "$_->{loginName}\n" for(@$_) ;
}

ok( $members->{'No specific role'}[0]{loginName} eq 'a-peer');

