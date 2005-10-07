
package WWW::SourceForge::Project;

use Cwd;
use Carp;
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
    my ($desc,$meta) = $content =~ m{<HR SIZE="1" NoShade><BR>
[\s\n]*<TABLE WIDTH="100%" BORDER="0">
[\s\n]*<TR><TD WIDTH="99%" VALIGN="top">
[\s\n]*<p>(.+?)<UL>(.+?)</UL>}s;

    die "Could not recognize project page format - has SF changed its layout?\n"
        unless $desc;

    $desc =~ s/^\s+//s;
    $desc =~ s/\s+$//s;
    $proj = {unixname => $pname, description => $desc};

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
    my $wa_list = $wa->find_link(url_regex => qr|/mail/\?|);
    if ($wa_list) {
        $links{lists} = "http://sourceforge.net". ($wa_list)->url;
    }
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

=head2 MailingLists

Returns a hashref of hashes containing information about the project's
mailing lists.  Each mailing list is a separate entry in the hash, keyed
by its list name.  The individual mailing list hashes have the following
data members:

    posts     - Total number of posts made to the list
    members   - Current number of mailing list subscribers

Returns undef in the case of an error.

=cut
sub MailingLists {
    my $self = shift;

    my $wa = WWW::Mechanize->new;
    my $lists = $self->{lists};
    $lists = $self->{lists} = {} if ($param->{refresh});
    return $lists if(keys %$lists);

    return undef if (! $self->{links}->{lists});

    $wa->get($self->{links}->{lists});
    sleep(1);
    $wa->follow_link(url=>$self->{links}->{lists});
    my $content = $wa->content;

    foreach my $line (split /\/mailarchive\/forum\.php\?forum_id/, $content) {
        next unless $line =~ m|([\w-]+)\s*Archives</a>\s*(\d+)\s*messages|i;
        my ($listname, $posts, $members) = ($1, $2, 0);
        $line =~ m|Approximate subscriber count\:\s*(\d+)|;
        $members = $1;

        # Convert e.g 42,123 -> 42123
        $posts =~ s/\,//g;
        $members =~ s/\,//g;

        $self->{lists}->{ $listname }->{ 'posts' } = $posts;
        $self->{lists}->{ $listname }->{ 'members' } = $members;
    }
    return $self->{lists};
}

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
    my $prjname = shift || carp "No project name given!\n";
    return "http://sourceforge.net/projects/" . $prjname;
}



"True";

