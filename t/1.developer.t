#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;

use WWW::SourceForge::Project;

my $sfp = WWW::SourceForge::Project->new('chewingosx');

die "Invalid Project\n" unless $sfp;

my $members = $sfp->Member;

use YAML;
print YAML::Dump($members);
for(values %$members) {
    print "$_->{loginName}\n" for(@$_) ;
}

ok( $members->{'No specific role'}[0]{loginName} eq 'clkao');
ok( $members->{'Project Manager'}[0]{loginName} eq 'gugod');
