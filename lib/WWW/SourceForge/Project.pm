
package WWW::SourceForge::Project;

use Cwd;
use WWW::Mechanize;
use HTML::TableExtract;

use vars qw($VERSION);
$VERSION = '0.09';

=head1 NAME

WWW::Source::Project - A class presenting sourceforge projects.

=head1 SYNOPSIS

use strict;
use WWW::SourceForge::Project;
use Data::Dumper;

my $pname = 'gaim';

my $proj = WWW::SourceForge::Project->new($pname);

die "Invalid project\n" unless $proj;

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

    # Wrong project unixname ?
    if($content =~ m{<H2><font color="#FF3333">Invalid Project</font></H2>}i) {
        return;
    }

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
    $links{developers} = ($wa->find_link(url_regex => qr/memberlist\.php/))->url;
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
    my $members = $self->{members};
    $members = $self->{members} = {} if ($param->{refresh});
    return $members if(keys %$members);

    $wa->get($self->{links}->{home});
    sleep(1);
    $wa->follow_link(url=>$self->{links}->{developers});
    my $content = $wa->content;

    my $te = HTML::TableExtract->new( headers => ['Developer','Username','Role/Position','Email','Skills'] );
    $te->parse($content);

    for my $ts ($te->table_states) {
        for my $row ($ts->rows) {
            my ($realName,$loginname,$position,$email,$skills) = @$row[0..4];
            $position = 'No specific role' if($position =~ /^\s*$/);
            push @{$members->{$position}||=[]} ,
                {
                    realName  => $realName,
                    loginName => $loginname,
                    position  => $position,
                    email     => $email,
                    skills    => $skills,
                };
        }
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


=head2 FetchCVSRepository( )

Fetch and save the cvs repository tarball into current working
directory.

=cut

sub FetchCVSRepository {
    my $self = shift;
    my $project = $self->{unixname};
    my $url = "http://cvs.sourceforge.net/cvstarballs/${project}-cvsroot.tar.bz2";
    my $wa  = WWW::Mechanize->new( autocheck => 1);
    $wa->get($url, ":content_file" => "${project}-cvsroot.tar.bz2" );
}

# privates

sub _projurl {
    return "http://sourceforge.net/projects/" . $_[0];
}



"True";

