
package WWW::SourceForge;

use vars qw/$VERSION/;

$VERSION = '0.01';

1;

__END__

=head1 NAME

WWW::SourceForge - Retrive infromation from SourceForge site.

=head1 SYNOPSIS

use WWW::SourceForge::Project;
use Data::Dumper;

my $proj = WWW::SourceForge::Project->new('gaim');

print Dump $proj;


=head1 DESCRIPTION

This module help you to retrive Project information from sourceforge
site.

So far the module itself is useless, all function is in
L<WWW::SourceForge::Project>.

=head1 COPYRIGHT

Copyright 2003 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
