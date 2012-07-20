
package WWW::SourceForge;

use vars qw/$VERSION/;
use WWW::Mechanize;
$VERSION = '0.10';

=head1 NAME

WWW::SourceForge - Retrieve infromation from SourceForge site.

=head1 SYNOPSIS

use WWW::SourceForge::Project;
use Data::Dumper;

my $proj = WWW::SourceForge::Project->new('gaim');

my @top10 = $proj->most_active;
my @top100 = $proj->active_list(100);

=head1 DESCRIPTION

This module help you to retrive Project information from sourceforge
site.

So far the module itself is useless, all function is in
L<WWW::SourceForge::Project>.

=cut

use constant {
    HOMEPAGE => 'http://sourceforge.net/' ,
};

=head2 new()

Return an WWW::SourceForge project.

=cut

sub new {
    my $class = shift;
    my $self = { wa => undef };
    return bless $self, $class;
}


=head2 most_active($self)

This method retrive top 10 project in the active list.

=cut

sub most_active {
    my $wa = $self->{wa} || WWW::Mechanize->new(autocheck => 1);
    my $r = $wa->get(HOMEPAGE);
    my @top10;
    my $content = $wa->content;
    while ($content=~ m{<b>(\d+)</b> <A HREF="/projects/(\w+?)/">(.+?)</A><BR>\n}igs) {
        push @top10 , { unixname => $2 , name => $3 };
    }
    return wantarray? @top10 : \@top10;
}

=head2 active_list($self,$n)

This method retrive top-n projects in the most active list.

=cut

sub active_list {
    my ($self,$topn) = @_;
    $topn ||= 50;
    my @top;

    my $wa = $self->{wa} || WWW::Mechanize->new(autocheck => 1);
    $wa->get(HOMEPAGE);
    $wa->follow_link( text_regex => qr/More Activity/i);
    push @top, $self->parse_list_table($wa->content);

    my $n = 50;
    while (my $link = $wa->find_link(text_regex => qr/-->/i)) {
        last if $n >= $topn;
        sleep(1);
        $wa->follow_link( url => $link->url);
	push @top,$self->parse_list_table($wa->content);
        $n += 50;
    }

    @top = sort { $b->{percentile} <=> $a->{percentile} }@top;
    return wantarray? @top : \@top;
}


sub parse_list_table {
    my ($self,$c) = @_;
    my @top;
    while ($c =~ m{(<TR.*?>(.*?)</TR>)}g) {
	my $line = $2;
	if($line =~ m{href="/projects/(.+?)/">(.+?)</a>.*?</TD><TD.*?>(.+?)</TD>}) {
	    push @top, { unixname => $1 , name => $2 , percentile => $3 };
	    print STDERR "[[$1 , $2 , $3]]\n";
	}
    }
    return @top;
}

1;

__END__


=head1 COPYRIGHT

Copyright 2003 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
