#!/usr/bin/env perl
# Author: gugod@ib.gugod.org
# Purpose: Fetch SourceForge project basic info, dump into a yaml.

use strict;
use WWW::SourceForge::Project;
use YAML qw(DumpFile);

my $pname = $ARGV[0] || die('You should give a project UNIXname');

my $proj = WWW::SourceForge::Project->new($pname);

DumpFile("$pname.yaml",$proj);
