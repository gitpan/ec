package Attachment_Dialog;
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

# Base 64 encoder and decoder filter
my $base64enc = &expand_path('~/.ec/encdec');

my @attachments = ();  # File attachments for outgoing messages.

my $fileselect = undef;

sub Select_Attachment {
    my ($cw,$selection) = @_;
    $cw->{Configure}{-attachment} = $selection;
    if ($cw->{Configure}{-caller} eq 'main') {
	$cw->{Configure}{-outputfile} = "Output File: ".
	    $cw->{Configure}{-lwd}.'/'.$selection;
    }
}

sub Populate {
  my ($w, $args) = @_;
  require Tk::Button;
  require Tk::Toplevel;
  require Tk::Label;
  require Tk::Listbox;

  $w -> SUPER::Populate($args);
  $w -> withdraw;
  $#attachments = -1;

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
  $list -> grid(-row => 1, -column => 1, -columnspan => 5, -pady => 5,
		-sticky => 'nswe');
  $list -> bind ('<Button-1>' => 
		 [$w => 'Select_Attachment', Ev(['getSelected'])]);

  my $filelabel =
    $w -> Component (Label => 'filelabel',
		     -textvar => \$w->{Configure}{-outputfile}, 
		     -font => $w->{Configure}{-font})
    ->grid( -row => 2, -column => 1, -sticky => 'w', -padx => 5,
	    -columnspan => 5 );
  my $bdelete = $w->Component (Button => 'deletebutton',
			       -text => 'Delete', -width => 8,
			       -command => sub{$w->Delete_Attachment},
			       -font => $w->{Configure}{-font},
			       -default => 'active');
  $bdelete->grid( -column => 1, -row => 3, -padx => 5, -pady => 5 );
  my $bbrowse = $w->Component (Button => 'browsebutton',
			       -text => 'Browse...', -width => 8,
			  -command => sub{$w->Browse_File},
                          -font => $w->{Configure}{-font},
		          -default => 'active' );
  $bbrowse->grid( -column => 2, -row => 3, -padx => 5, -pady => 5 );
  my $bsave = $w->Component (Button => 'savebutton',
			     -text => 'Save', -width => 8,
			     -command => sub{$w->Save_Attachment},
			     -font => $w->{Configure}{-font},
			     -default => 'active' );
  $bsave->grid( -column => 3, -row => 3, -padx => 5, -pady => 5 );
  my $battach = $w->Component (Button => 'attachbutton',
			       -text => 'Attach', -width => 8,
			       -command => sub{$w->Attach},
			       -font => $w->{Configure}{-font},
			       -default => 'active' );
  $battach->grid( -column => 4, -row => 3, -padx => 5, -pady => 5 );
  my $bdismiss = $w->Component (Button => 'dismissbutton',
				-text => 'Dismiss', -width => 8,
				-command => sub{$w->Dismiss},
				-font => $w->{Configure}{-font},
				-default => 'active' );
  $bdismiss->grid( -column => 5, -row => 3, -padx => 5, -pady => 5 );

  $w->ConfigSpecs(
        -font             => ['CHILDREN',undef,undef,undef],
	-lwd              => ['PASSIVE',undef,undef,"Output File:"],
	-caller           => ['PASSIVE',undef,undef,undef],
	-file             => ['PASSIVE',undef,undef,""],
	-folder           => ['PASSIVE',undef,undef,'.'],
	-attachment       => ['PASSIVE',undef,undef,''],
        -outputfile       => ['PASSIVE',undef,undef,''],
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

sub Dismiss {
    my ($cw,@args) = @_;
    $cw->{Dismiss} = 1;
    $#attachments = -1;
}

sub Show {
    my ($cw,@args) = @_;
    my $wd = cwd;
    $cw -> configure ( -lwd => $wd );
    $cw -> configure ( -outputfile => "Output File: $wd/" );
    $cw->Popup(@args);
    $cw->focus;
    
    if ($cw->{Configure}{-caller} =~ /main/) {
	&watchcursor ($cw);
	$cw->Subwidget('deletebutton') -> configure(-state => 'disabled');
	$cw->Subwidget('attachbutton') -> configure(-state => 'disabled');
	$cw->Subwidget('browsebutton') -> configure(-state => 'disabled');
	eval {
	    &list_attachments( $cw -> Subwidget ('attachmentlist'), 
	       $cw->{Configure}{-folder}.'/'.$cw->{Configure}{-file});
	};
	&defaultcursor ($cw);
    } elsif ($cw->{Configure}{-caller} =~ /compose/) {
	$cw->Subwidget('savebutton') -> configure(-state => 'disabled');
	$cw->{Configure}{-outputfile} = '';
    }
    $cw -> waitVariable(\$cw->{Dismiss});
    $fileselect = undef;
    $cw->WmDeleteWindow;
    return @attachments;
}

sub Delete_Attachment {
  my ($cw) = @_;
  my (@newattachments, $selected);
  my $l = $cw -> Subwidget('attachmentlist');
  if( $l -> curselection ne '' ) {
    $selected = $l -> get( $l -> curselection );
    $l -> delete( $l -> curselection );
    foreach( @attachments ) {
      push @newattachments, ($_) unless $_ eq $selected;
    }
    $#attachments = -1;
    foreach (@newattachments) {
      push @attachments, ($_);
    }
  }
  $cw->{Configure}{-outputfile} = '';
}

sub Browse_File {
  my ($cw,$dir) = @_;
  my $l = $cw -> Subwidget('attachmentlist');
  if (not defined $fileselect) {
      $fileselect = $cw -> SimpleFileSelect (-title => $dir);
  }
  my $resp = $fileselect -> Show;
  chomp $resp;
  if( -f $resp ) {
    push @attachments, ($resp);
    $l -> insert( 'end', $resp );
  }
  $cw->{Configure}{-outputfile} = '';
}

sub Attach {
    shift->{Dismiss} = 1;
}

sub Save_Attachment {
  my ($cw) = @_;
  my $l = $cw -> Subwidget( 'attachmentlist' );
  my (@contents,$attachment,$afilename,$boundary,$cstr);
  $afilename = $l -> get( $l -> curselection );
  return if (not defined $afilename or (not length $afilename));
  $cw->{Configure}{-outputfile} = "Output File: ". 
      $cw->{Configure}{-lwd}.'/'.$afilename;
  require Tk::SimpleFileSelect;
  my $currentfolder = $cw->{Configure}{-folder};
  my $msg = $cw->{Configure}{-file};
  &watchcursor ($cw);
  eval {
     @contents = content("$currentfolder/$msg");
     $cstr = content_as_str("$currentfolder/$msg");
     $boundary = '--'.boundary(@contents);
     $cstr =~ /filename\=\"$afilename\".*?\n\n(.*?)$boundary/ism;
     $attachment = $1;
     my $decoded = &decode64 ($attachment);
     if( -f $afilename ) {
       require Tk::Dialog;
       my $ed = $cw -> Dialog( -title => 'Save Attachment',
	-text => "File $afilename exists.\nOverwrite?",-bitmap => 'question',
	-font => $config->{menufont},-buttons => ['Yes', 'No'],
        -default_button => 'Yes' );
       my $resp = $ed -> Show;
       return if $resp !~ /Yes/;
     }
     open OUTPUT, ">$afilename" or
       warn "Couldn't write $afilename: $!\n";
     print OUTPUT $decoded;
     close OUTPUT;
  };
  &defaultcursor ($cw);
  return 1;
}

sub decode64 {
  my ($attachstr) = @_;
  my ($decoded);
  open OUT, ">/tmp/ecattach$$" or
    warn "Couldn't write temporary input file for decoding: $!\n";
  print OUT $attachstr;
  close OUT;
  open DECODE, "$base64enc \-d \-b \</tmp/ecattach$$ |"
    or warn "Couldn't decode attachment: $!\n";
  while ( <DECODE> ) { $decoded .= $_ }
  close DECODE;
  unlink "/tmp/ecattach$$";
  return $decoded;
}

sub boundary {
  my (@txt) = @_;
  my @boundary = grep /boundary=/i, @txt;
  return '' if not defined $boundary[0];
  $boundary[0] =~ s/.*boundary=\"(.*)\".*/$1/i;
  return $boundary[0];
}

sub list_attachments {
  my($lb, $messagefile) = @_;
  my (@filenames, @contents, $line);
  eval {
    @contents = content($messagefile);
    @filenames = grep /filename=/i, @contents;
    foreach $line (@filenames) {
      $line =~ s/.*\"(.*)\"/$1/;
      $lb -> insert ('end', $line);
    }
  };
}

sub content_as_str {
  return join "\n", &content(@_);
}

sub content {
  my ($msg) = @_;
  my ($l, @contents);
  eval {
    open MESSAGE, $msg or
      die "Couldn't open $msg: ".$!."\n";
    while (defined ($l=<MESSAGE>)) {
      chop $l;
      push @contents, ($l);
    }
    close MESSAGE;
  };
  return @contents;
}

sub watchcursor {
  my ($mw) = @_;
  $mw -> Busy( -recurse => '1' );
}

sub defaultcursor {
  my ($mw) = @_;
  $mw -> Unbusy( -recurse => '1' );
}

1;
