
package WWW::SourceForge::Project;

use WWW::Mechanize;

use vars qw($VERSION);
$VERSION = '0.02';

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

    @$proj{'Homepage'} = $content =~ m{<!-- end sub section title--><A href="(.+?)">&nbsp;Project Home Page</A>}s;

    return bless($proj,$class);
}

# More site function here.

sub Tracker {}

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

