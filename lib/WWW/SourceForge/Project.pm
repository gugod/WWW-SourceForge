
package WWW::SourceForge::Project;

use WWW::Mechanize;

use vars qw($VERSION);
$VERSION = '0.05';

=head1 NAME

WWW::Source::Project - A class presenting sourceforge projects.

=head1 SYNOPSIS

use strict;
use WWW::SourceForge::Project;
use Data::Dumper;

my $pname = 'gaim';

my $proj = WWW::SourceForge::Project->new($pname);

print Dumper $proj->Member;

=head1 DESCRIPTION

This object use L<WWW::Mechanize> to grab any informations of a project
from sourceforge website.

=head1 METHODS


=head2 new($unixname)

Return an object of project with given unixname.

=cut

sub new {
    my ($class,$pname) = @_;
    my $url = _projurl($pname);
    my $proj;
    my $wa  = WWW::Mechanize->new( autocheck => 1);
    $wa->get($url);
    my $content = $wa->content;
    # Project description
    my ($foo,$meta) = $content =~ m{<HR SIZE="1" NoShade><BR>
<TABLE WIDTH="100%" BORDER="0">
<TR><TD WIDTH="99%" VALIGN="top">
<p>(.+?)<p>(?:.+?)<UL>(.+?)</UL>}s;
    $foo =~ s/^\s+//s;
    $foo =~ s/\s+$//s;
    $proj = {unixname => $pname, description => $foo};

    @$proj{name} = $content =~ m{<TITLE>SourceForge.net: Project Info - (.+)</TITLE>};
    foreach (split(/<LI> /,$meta)) {
        s/\s*<BR>//;
        my ($k,$v) = split /: /;
        next unless $k;
        $v =~ s{<A [^>]+?>(.+?)</A>}{$1}g;
        if ($v =~ /,/) {
            my @vlist = split(/\s*,\s*/,$v);
            $proj->{$k} = \@vlist;
        } else {
            $proj->{$k} = $v;
        }
    }

    # Parse Track Numbers
    @$proj{'Homepage'} = $content =~ m{<!-- end sub section title--><A href="(.+?)">&nbsp;Project Home Page</A>}s;
    @$proj{'oBugs','nBugs'} = $content =~ m{Bugs</A>\s+\( <B>(\d+?) open / (\d+?) total</B> \)};
    @$proj{'oSupports','nSupports'} = $content =~ m{Requests</A>\s+\( <B>(\d+?) open / (\d+?) total</B> \)<BR>};
    @$proj{'oPatches','nPatches'} = $content =~ m{Patches</A>\s+\( <B>(\d+?) open / (\d+?) total</B> \)<BR>};
    @$proj{'oFeatures','nFeatures'} = $content =~ m{Feature Requests</A>\s+\( <B>(\d+) open / (\d+) total</B> \)};

    # Parse Admin
    my @admin;
    my ($prjadmins) = $content =~ m{Project Admins:</SPAN><BR>(.+?)<HR WIDTH="100%" SIZE="1" NoShade>}s;
    while ($prjadmins =~ m{<a href="/users/(\w+?)/">\w+?</a>(.*?)<BR>}sg) {
        push @admin,$1;
    }
    $proj->{Admin} = \@admin;

    # Find important links
    my %links;
    $links{home} = $wa->uri;
    $links{developers} = ($wa->find_link(text_regex => qr/View Members/))->url;

    $proj->{links} = \%links;
    $proj->{_wa}   = $wa;
    $proj->{members} = {};
    return bless($proj,$class);
}

# More site function here.

=head2 Admin

Return a list, or arrayref, of member objects who are project administrators.

=cut

sub Admin {
    my $self = shift;
    my $admin = $self->{Admin};
    return wantarray? @$admin : $admin ;
}

=head2 Member($param)

Return a hashref of all project members. Organized as

$pm->{<Position>}->{<field>}

=cut

sub Member {
    my($self,$param) = @_;
    my $wa   = WWW::Mechanize->new;
    $wa->get($self->{links}->{home});
    $wa->follow_link(url=>$self->{links}->{developers});
    my $content = $wa->content;

    my $members = $self->{members};
    $members = $self->{members} = {} if ($param->{refresh});
    return $members if(keys %$members);

    while ($content =~ m{<tr>\s+<td>(.+?)</td>\s+<td.+?><a href="/users/(\w+?)/">\w+?</a>.*?</td>\s+<td.+?>(.*?)</td>\s+<td.+?><A href=".+?">(.+?)</td>\s+<td.+?>\s+</tr>}g) {
        my ($realName,$loginname,$position,$email) = ($1,$2,$3,$4);
        $email =~ s/\s+at\s+/@/;
        $position =~ s/\s*\(.+\)\s*//; # strip inline comments.
        $position =~ s/^\s+//;
        $position ||= 'No specific role';
        if ($realName =~ m{<A.+?>(.+?)</A}) {
            $realName =$1;
        }
        push @{$members->{$position}||=[]} ,
          {
           realName  => $realName,
           loginName => $loginname,
           position  => $position,
           email     => $email,
          };
    }

    $self->{members} = $members;
    return $self->{members};
}

sub Tracker {
    my $s = shift;
    my $r;
    foreach (qw/Bugs Supports Patches Features/) {
        $r->{$_} = [$s->{"o$_"}, $s->{"n$_"}];
    }
    return $r;
}

sub Forum {}

sub DocManager {}

sub TaskManager {}

sub Latestnews {}

# yawp!

sub MakeDonation {}

# privates

sub _projurl {
    return "http://sourceforge.net/projects/" . $_[0];
}



"True";

