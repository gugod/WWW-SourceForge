
package WWW::SourceForge::Project;

use WWW::Mechanize;

sub new {
    my ($class,$pname) = @_;

    my $url = "http://sourceforge.net/projects/$pname";
    my $proj;
    my $a  = WWW::Mechanize->new( autochcheck => 1);
    $a->agent_alias("Mac Mozilla");
    $a->get($url);
    my $content = $a->content;
    # Project description
    my ($foo,$meta) = $content =~ m{<HR SIZE="1" NoShade><BR>
<TABLE WIDTH="100%" BORDER="0">
<TR><TD WIDTH="99%" VALIGN="top">
<p>(.+?)<p>(?:.+?)<UL>(.+?)</UL>}s;
    $foo =~ s/^\s+//s;
    $foo =~ s/\s+$//s;
    $proj = {name => $pname, description => $foo};

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




"True";

