package EC::Attachment_Dialog;
my $RCSRevKey = '$Revision: 1.1 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;

use Tk qw(Ev);
use strict;
use Carp;
use Cwd;
use base qw(Tk::Toplevel);
use Tk::widgets qw(Button Frame Label Listbox);

Construct Tk::Widget 'Attachment_Dialog';

require EC::Config;
my $cfgfilename = &expand_path('~/.ec/.ecconfig');
my $config = &EC::Config::new ($cfgfilename);

sub Select_Attachment {
    my ($cw,$selection) = @_;
    $cw->{Configure}{-attachment} = $selection;
}

sub Populate {
  my ($w, $args) = @_;
  require Tk::Button;
  require Tk::Toplevel;
  require Tk::Label;
  require Tk::Listbox;

  $w -> SUPER::Populate($args);
  $w -> withdraw;
  $#{$w->{configure}{-attachments}} = -1;

  if (defined $args->{-font}) {
      $w -> {Configure}{-font} = $args->{-font};
  } else {
      $w->{Configure}{-font}=$config->{menufont};
  }
  if (defined $args->{-file}) {
      $w ->{Configure}{-file}=$args->{-file};
  }

  my $list = $w -> Component (
     ScrlListbox => 'attachmentlist', -scrollbars => 'osoe');
  $list -> Subwidget ('yscrollbar') -> configure (-width => 10);
  $list -> Subwidget ('xscrollbar') -> configure (-width => 10);
  $list -> grid(-row => 1, -column => 1, -columnspan => 3, -pady => 5,
		-sticky => 'nswe');
  $list -> bind ('<Button-1>' => 
		 [$w => 'Select_Attachment', Ev(['getSelected'])]);

  my $bbrowse = $w->Component (Button => 'browsebutton',
			       -text => 'Attach...', -width => 8,
			  -command => sub{$w->Browse_File},
			       -font => $w->{Configure}{-font});
  $bbrowse->grid( -column => 1, -row => 2, -padx => 5, -pady => 5 );
  my $bdelete = $w->Component (Button => 'deletebutton',
			       -text => 'Remove', -width => 8,
			       -command => sub{$w->Delete_Attachment},
			       -font => $w->{Configure}{-font});
  $bdelete->grid( -column => 2, -row => 2, -padx => 5, -pady => 5 );
  my $bclose = $w->Component (Button => 'closebutton',
				-text => 'Close', -width => 8,
				-command => sub{$w->Close},
				-font => $w->{Configure}{-font});
  $bclose->grid( -column => 3, -row => 2, -padx => 5, -pady => 5 );

  $w->ConfigSpecs(
        -font             => ['CHILDREN',undef,undef,undef],
	-lwd              => ['PASSIVE',undef,undef,"Output File:"],
	-file             => ['PASSIVE',undef,undef,""],
	-folder           => ['PASSIVE',undef,undef,'.'],
	-attachments      => ['PASSIVE',undef,undef,()],
        -close            => ['PASSIVE',undef,undef,0],
  );
  return $w;
}

# prepend $HOME directory to path name in place of ~
sub expand_path {
  my ($s) = @_;
  if( $s =~ /^\~/ ) {
    $s =~ s/~//;
    $s = $ENV{'HOME'}."/$s";
  }
  $s =~ s/\/\//\//g;
  return $s;
}

sub Close {
    my ($cw,@args) = @_;
    $cw->{configure}{-close} += 1;
}

sub Show {
    my ($cw,@args) = @_;
    my $wd = cwd;
    $cw -> configure ( -lwd => $wd );
    $cw->Popup(@args);
    $cw->focus;
    
    $cw -> waitVariable(\$cw->{configure}{-close});
    $cw->withdraw;
    return @{$cw->{configure}{-attachments}};
}

sub Delete_Attachment {
  my ($cw) = @_;
  my (@newattachments, $selected);
  my $l = $cw -> Subwidget('attachmentlist');
  if( $l -> curselection ne '' ) {
    $selected = $l -> get( $l -> curselection );
    $l -> delete( $l -> curselection );
    foreach( @{$cw->{configure}{-attachments}} ) {
      push @newattachments, ($_) unless $_ eq $selected;
    }
    $#{$cw->{configure}{-attachments}} = -1;
    foreach (@newattachments) {
      push @{$cw->{configure}{-attachments}}, ($_);
    }
  }
}

sub Browse_File {
  my ($cw,$dir) = @_;
  my $l = $cw -> Subwidget ('attachmentlist');
  my $fileselect = $cw -> SimpleFileSelect (-title => $dir);
  my $resp = $fileselect -> Show;
  $fileselect -> destroy;
  chomp $resp;
  if (-f $resp) {
    push @{$cw->{configure}{-attachments}}, ($resp);
    $l -> insert ('end', $resp);
  }
}

1;
