#!/usr/bin/env perl -w

use strict;
use File::stat;
use Test::Simple skip_all => "cvs.sf.net very unstable.";

use WWW::SourceForge::Project;

my $sfp = WWW::SourceForge::Project->new('chewingosx');

# May failed.
$sfp->FetchCVSRepository;

my $filename = "chewingosx-cvsroot.tar.bz2";

my $sb = stat($filename);

ok( $sb->size == 4868 );

unlink($filename);

