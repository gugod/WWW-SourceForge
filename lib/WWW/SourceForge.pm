
package WWW::SourceForge;

use vars qw/$VERSION/;
use WWW::Mechanize;
$VERSION = '0.04';

use constant {
    HOMEPAGE => 'http://sourceforge.net/' ,
};

sub new {
    my $class = shift;
    my $self = { wa => undef };
    return bless $self, $class;
}

sub most_active {
    my $wa = $self->{wa} || WWW::Mechanize->new(autocheck => 1);
    my $r = $wa->get(HOMEPAGE);
    my @top10;
    my $content = $wa->content;
    while ($content=~ m{<b>(\d+)</b> <A HREF="/projects/(\w+?)/">(.+?)</A><BR>\n}gs) {
        push @top10 , { unixname => $2 , name => $3 };
    }
    return wantarray? @top10 : \@top10;
}

sub active_list {
    my ($self,$topn) = @_;
    $topn ||= 50;
    my $wa = $self->{wa} || WWW::Mechanize->new(autocheck => 1);
    $wa->get(HOMEPAGE);
    my @content;
    my @top;
    $wa->follow_link( text_regex => qr/More Activity/i);
    push @content, $wa->content;
    my $n = 50;

    while (my $link = $wa->find_link(text_regex => qr/More --/i)) {
        last if $n >= $topn;
        $wa->follow_link( url => $link->url);
        push @content, $wa->content;
        $n += 50;
    }

    for my $c (@content) {
        while ($c =~ m{<TD>&nbsp;&nbsp;(\d+?)</TD><TD><A href="/projects/(\w+?)/">(.+?)</A></TD><TD align="right">(.+?)</TD></TR><TR BGCOLOR="#.+?">}sg) {
            push @top, { unixname => $2 , name => $3 , percentile => $4 };
        }
    }
    @top = sort { $b->{percentile} <=> $a->{percentile} }@top;
    return wantarray? @top : \@top;
}


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
