
package WWW::SourceForge::Project;

use WWW::Mechanize;

use vars qw($VERSION);
$VERSION = '0.04';

sub new {
    my ($class,$pname) = @_;
    my $url = _projurl($pname);
    my $proj;
    my $wa  = WWW::Mechanize->new( autochcheck => 1);
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

    return bless($proj,$class);
}

# More site function here.

sub Admin {
    my $self = shift;
    my $admin = $self->{Admin};
    return wantarray? @$admin : $admin ;
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

