
package WWW::SourceForge::User;

use WWW::Mechanize;

use vars qw($VERSION);
$VERSION = '0.01';

sub new {
    my ($class,$pname) = @_;
    my $url = _userurl($pname);
    my $proj;
    my $wa  = WWW::Mechanize->new( autochcheck => 1);
    $wa->get($url);
    my $content = $wa->content;

    my ($userId) = $content =~ m{<TD>User ID: </TD>\s+<TD><B>(\d+)</B>}s;
    my ($realName) = $content =~ m{<TR valign=top>\s+<TD>Real Name: </TD>\s+<TD><B>(.+?)</B></TD>\s+</TR>}s;
    my ($email) = $content =~ m{<TD>Email Address: </TD>\s+<TD>\s+<B><A HREF=".+?">(.+?)</A></B>\s+</TD>}s;
    $email =~ s/\s+at\s+/\@/;
    my ($prjinfo) = $content =~ m{<H4>Project Info</H4>(.+?)</ul>\s+</TD>\s+</TR>\s+</TABLE>\s+</TD>\s+<TD> &nbsp; </TD>\s+</TR>\s+</TABLE>}s;
    my @projects;
    while ($prjinfo =~ m{<BR><A href="/projects/(.+?)/">(.+?)</A>}sg) {
        push @projects, $1;
    }
    my $sfu = {
               userId => $userId,
               realName => $realName,
               email => $email,
               projects => \@projects,
              };
    return bless($sfu,$class);
}

# More user function here.

sub UserId { return $_[0]->{userId};}

sub RealName { return $_[0]->{realName};}

sub Email { return $_[0]->{email}}

sub Projects{
    my $p = $_[0]->{projects};
    return wantarray? @$p : $p;
}

# yawp!

sub MakeDonation {}

# privates

sub _userurl {
    return "http://sourceforge.net/users/" . $_[0];
}

"Wazaaaaahhh....";
