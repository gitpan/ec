package EC::About;
my $RCSRevKey = '$Revision: 1.1 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(Button Frame Label);

Construct Tk::Widget 'About';

sub Populate {
  my ($w, $args) = @_;
  require Tk::Button;
  require Tk::Toplevel;
  require Tk::Label;
  require Tk::Listbox;
  $w -> SUPER::Populate($args);
  my $l = $w -> Component( Label => 'tile',
	   -text => "\nEC Email Client\n Version ".$args->{-version}."\n",
			 -font => $args->{-font} );
  $l -> grid( -column => 1, -row => 1, -padx => 5, -pady => 5 );
  my $l2 = $w -> Component( Label => 'copyright',
   -text => "Copyright \xa9 2001, rkiesling\@mainmatter.com\n\n" .
   "Please refer to the file \"Artistic\" \n" .
   "for license terms\n",
   -font => $args->{-font});
  $l2 -> grid( -column => 1, -row => 2, -padx => 5, -pady => 5 );
  $b = $w->Button( -text => 'Dismiss', -command => sub{$w->WmDeleteWindow},
                   -font => $args->{-font},
		   -default => 'active' );
  $b->grid( -column => 1, -row => 3, -padx => 5, -pady => 5 );
  $b->focus;

  $w->ConfigSpecs(
        -font             => ['CHILDREN',undef,undef,undef],
        -version          => ['PASSIVE',undef,undef,0],
  );
  return $w;
}

1;
