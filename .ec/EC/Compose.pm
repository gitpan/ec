package EC::Compose;
my $RCSRevKey = '$Revision: 0.01 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=0.61;
use vars qw($VERSION @EXPORT_OK);
@EXPORT_OK = qw(glob_to_re);

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(Text Button Frame Menu Scrollbar);
use File::Basename;

Construct Tk::Widget 'Compose';

# Message header fields.
my $fromfield = "From:";
my $tofield = "To:";
my $ccfield = "Cc:";
my $subjfield = "Subject:";
my $bccfield = "Bcc:";
my $fccfield = "Fcc:";
my $replytofield = "Reply-To:";
my $msgidfield = "Message-Id:";
my $msgsep = "--- Enter the message text below this line\. ---";
my $sigsep = "-- ";

my $cfgfilename = &expand_path('~/.ec/.ecconfig');
my $config = &EC::Config::new ($cfgfilename); 

sub Close {
   my ($cw) = @_;
   $cw->{Withdraw} = '1';
}

# sub Accept_dir
# {
#  my ($cw,$new) = @_;
#  my $dir  = $cw->cget('-directory');
#  $cw->configure(-directory => "$dir/$new",
# 	       -title => "$dir/$new" );
# }

# sub Open {
#   my ($cw) = @_;
#   my ($entry,$path);
#   $entry = $cw -> Subwidget('file_entry') -> get;
#   $path = $cw -> {'Configure'}{'-directory'};
#   if (defined $entry and length($entry)) {
#     if ( -d "$path/$entry" ) {
#       $cw -> directory( "$path/$entry" );
#       $cw -> Accept_dir;
#     } else {
#       $cw -> {Selected} = "$path/$entry";
#     }
#   }
# }

sub composemenu {
  my ($w) = @_;
  my $cm = $w -> Menu( -type => 'menubar', -font => $config->{menufont} );
#  my $composefilemenu = $cm -> Menu;
#  my $composeeditmenu = $cm -> Menu;
#  my $optionalfieldsmenu = $cm -> Menu;
#  $cm -> add( 'cascade', -label => 'File', -menu => $composefilemenu );
#  $cm -> add( 'cascade', -label => 'Edit', -menu => $composeeditmenu );
#  $composefilemenu -> add( 'command', -label => 'Insert File...',
#			   -accelerator => 'Alt-I',
#			   -font => $config->{menufont},
#			   -command => sub {&InsertFileDialog($w)});
#  $composefilemenu -> add( 'separator' );
#  $composefilemenu -> add( 'command', -label => 'Minimize', -state => 'normal',
#		  -font => $config->{menufont}, -accelerator => 'Alt-Z',
#		  -command => sub{$w->toplevel->iconify});
#  $composefilemenu -> add( 'command', -label => 'Attachments...',
#		   -font => $config->{menufont},
#		   -command => sub{ &attachment_dialog( $w, 'compose' ) } );
#  $composefilemenu -> add( 'command', -label => 'Close',
#			   -accelerator => 'Alt-W',
#			   -font => $config->{menufont},
#			   -command => sub { $w -> WmDeleteWindow } );
#  &EditMenuItems( $composeeditmenu, ($w -> Subwidget( 'text' )) );
#  my $optionalfields = &OptionalFields( $w -> Subwidget('text'));
#  $optionalfieldsmenu -> AddItems ( @$optionalfields );
#  $optionalfieldsmenu -> configure( -font => $config->{menufont} );
#  $composeeditmenu -> add( 'separator' );
#  $composeeditmenu -> add( 'cascade',  -label => 'Insert Field',
#			   -state => 'normal', -font => $config->{menufont},
#			   -menu => $optionalfieldsmenu );
  return $cm;
}

sub EditMenuItems {
  my ($m,$w) = @_;
     $m -> add ( 'command', -label => 'Undo',
				 -state => 'normal',
				 -accelerator => 'Alt-U',
				 -font => $config->{menufont},
				 -command => sub{$w -> undo});
    $m -> add ('separator');
    $m -> add ( 'command', -label => 'Cut', -state => 'normal',
				 -accelerator => 'Alt-X',
				 -font => $config->{menufont},
				 -command => sub{$w -> clipboardCut});
    $m -> add ( 'command', -label => 'Copy', -accelerator => 'Alt-C',
				 -state => 'normal',
				 -font => $config->{menufont},
				 -command => sub{$w -> clipboardCopy});
    $m -> add ( 'command', -label => 'Paste', -accelerator => 'Alt-V',
				 -state => 'normal',
				 -font => $config->{menufont},
				 -command => sub{$w -> clipboardPaste});
    $m -> add ( 'command', -label => 'Select All',
				 -accelerator => 'Ctrl-/',
				 -state => 'normal',
				 -font => $config->{menufont},
			 -command => sub{$w -> selectAll} );
}

sub OptionalFields {
  my ($t) = @_;
  return
    [
     [command=>'Bcc:', -command=>sub{insertfield($t,$bccfield)}],
     [command=>'Cc:', -command=>sub{insertfield($t,$ccfield)}],
     [command=>'Fcc:', -command=>sub{insertfield($t,$fccfield)}],
     [command=>'Reply-To:', -command=>sub{insertfield($t,$replytofield)}],
    ]
}

sub Populate {
    my ($w, $args) = @_;
    require Tk::TextUndo;
    require Tk::Button;
    require Tk::Dialog;
    require Tk::DialogBox;
    require Tk::Toplevel;
    require Tk::LabEntry;
    require Cwd;
    $w->SUPER::Populate($args);
    $w->protocol('WM_DELETE_WINDOW' => ['Cancel', $w ]);
    $w->withdraw;
    my $menu = &composemenu ($w);
    $menu -> pack (-anchor => 'w', -expand => 'x');
    my $l = $w -> Component( Label => 'entry_label',-text => 'File Name: ');
    $l -> grid( -column => 1, -row => 3, -padx => 5, -pady => 5 );
    my $e = $w -> Component(Entry => 'file_entry',
        -textvariable => \$w->{Configure}{-initialfile} );
    $e->grid(-column => 2, -columnspan => 1, -padx => 5, -pady => 5,
	     -row => 3, -sticky => 'e,w' );
    $e->bind('<Return>' => [$w => 'Open', Ev(['getSelected'])]);
    my $lb = $w->Component( ScrlListbox    => 'dir_list',
        -scrollbars => 'se', -width => \$w -> {Configure}{-width},
	-height => \$w -> {Configure}{-height} );
    $lb -> Subwidget('yscrollbar') -> configure(-width=>10);
    $lb -> Subwidget('xscrollbar') -> configure(-width=>10);
    $lb->grid( -column => 2, -row => 1, -rowspan => 2, -padx => 5,
	    -pady => 5, -sticky => 'nsew' );
    $lb->bind('<Double-Button-1>' => [$w => 'Open', Ev(['getSelected'])]);
    $lb->bind('<Button-1>', sub {($w->{Configure}{-initialfile}=
	    $lb->get($lb->curselection))&&($e->icursor( 'end' ))});
    $b = $w -> Component( 'Button' => 'acceptbutton',
	  -textvariable => \$w->{'Configure'}{'-acceptlabel'},
	  -underline => 0,-command => [$w => 'Open', Ev(['getSelected']) ]);
    $b->grid(-column=>1,-row=>1,-padx=>5,-pady=>5,-sticky=>'sew');
    $b = $w->Button( -text => 'Cancel', -underline => 0,
		     -command => [ 'Close', $w ]);
    $b->grid( -column => 1, -row => 2, -padx => 5, -pady => 5,
	    -sticky => 'new' );
    $w -> bind( '<Alt-c>', [$w => 'Cancel', $w]);
    $w -> Subwidget('file_entry') -> focus;
    $w -> eventAdd( '<<Accept>>', '<Alt-a>');
    $w -> bind('<<Accept>>', [$w => 'Open', Ev(['getSelected']) ]);
    $w->ConfigSpecs(
        -font             => ['CHILDREN',undef,undef,
			      '*-helvetica-medium-r-*-*-12-*'],
        -width            => [ ['dir_list'], undef, undef, 30 ],
        -height           => [ ['dir_list'], undef, undef, 14 ],
#        -directory        => [ 'METHOD', undef, undef, '.' ],
        -initialdir       => '-directory',
        -files            => [ 'PASSIVE', undef,undef,1 ],
        -dotfiles         => [ 'PASSIVE', undef,undef,0 ],
        -initialfile      => [ 'PASSIVE', undef, undef, '' ],
        -filter           => [ 'METHOD',  undef, undef, undef ],
        '-accept'         => [ 'CALLBACK',undef,undef, undef ],
        -create           => [ 'PASSIVE', undef, undef, 0 ],
        -acceptlabel      => [ 'PASSIVE', undef, undef, 'Accept' ],
        DEFAULT           => [ 'dir_list' ],
    );
    $w->Delegates(DEFAULT => 'dir_list');
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

# sub translate
#   {
#       my ($bs,$ch) = @_;
#       return "\\$ch" if (length $bs);
#       return '.*'  if ($ch eq '*');
#  return '.'   if ($ch eq '?');
#  return "\\."  if ($ch eq '.');
#  return "\\/" if ($ch eq '/');
#  return "\\\\" if ($ch eq '\\');
#  return $ch;
# }

# sub glob_to_re
# {
#  my $regex = shift;
#  $regex =~ s/(\\?)(.)/&translate($1,$2)/ge;
#  return sub { shift =~ /^${regex}$/ };
# }

# sub filter
# {
#  my ($cw,$val) = @_;
#  my $var = \$cw->{Configure}{'-filter'};
#  if (@_ > 1 || !defined($$var))
#   {
#    $val = '*' unless defined $val;
#    $$var = $val;
#    $cw->{'match'} = glob_to_re($val)  unless defined $cw->{'match'};
#    unless ($cw->{'reread'}++)
#     {
#      $cw->Busy;
#      if( ( $cw -> cget( '-connected' ) ) =~ /1/ ) {
#       $cw->afterIdle(['rereadRemote',$cw,$cw->cget('-directory')])
#      } else {
#        $cw->afterIdle(['reread',$cw,$cw->cget('-directory')])
#      }
#     }
#   }
#  return $$var;
# }

# sub defaultextension
# {
#  my ($cw,$val) = @_;
#  if (@_ > 1)
#   {
#    $val = ".$val" if ($val !~ /^\./);
#    $cw->filter("*$val");
#   }
#  else
#   {
#    $val = $cw->filter;
#    my ($ext) = $val =~ /(\.[^\.]*)$/;
#    return $ext;
#   }
# }

# sub directory
# {
#  my ($cw,$dir) = @_;
#  my $var = \$cw->{Configure}{'-directory'};
#  if (@_ > 1 && defined $dir)
#   {
#    if (substr($dir,0,1) eq '~')
#     {
#      if (substr($dir,1,1) eq '/')
#       {
#        $dir = $ENV{'HOME'} . substr($dir,1);
#       }
#      else
#       {my ($uid,$rest) = ($dir =~ m#^~([^/]+)(/.*$)#);
#        $dir = (getpwnam($uid))[7] . $rest;
#       }
#     }
#    $dir =~ s#([^/\\])[\\/]+$#$1#;
#    if (-d $dir)
#     {
#      unless (Tk::tainting())
#       {
#        my $pwd = Cwd::getcwd();
#        if (chdir( (defined($dir) ? $dir : '') ) )
#         {
#          my $new = Cwd::getcwd();
#          if ($new)
#           {
#            $dir = $new;
#           }
#          else
#           {
#            carp "Cannot getcwd in '$dir'";
#           }
#          chdir($pwd) || carp "Cannot chdir($pwd) : $!";
#          $cw->{Configure}{'-directory'} = $dir;
# 	 $cw->configure(-title=>$dir);
#         }
#        else
#         {
#          $cw->BackTrace("Cannot chdir($dir) :$!");
#         }
#       }
#      $$var = $dir;
#      unless ($cw->{'reread'}++)
#       {
#        $cw->Busy;
#        $cw->afterIdle(['reread',$cw])
#       }
#     }
#   }
#  return $$var;
# }


# sub reread
# {
#   my ($w) = @_;
#   my $dir = $w->cget('-directory');
#   my ($f, $seen);
#  if (defined $dir)
#   {
#    if (!defined $w->cget('-filter') or $w->cget('-filter') eq '')
#     {
#      $w->configure('-filter', '*');
#     }
#    my $dl = $w->Subwidget('dir_list');
#    $dl->delete(0, 'end');
#    local *DIR;
#    my $h;
#    if (opendir(DIR, $dir)) {
#      my $file = $w->cget('-initialfile');
#      my $seen = 0;
#      my $accept = $w->cget('-accept');
#      foreach $f (sort(readdir(DIR))) {
#        next if ($f eq '.');
#        next if $f =~ /^\.[^\.]/ and ! $w -> {Configure}{-dotfiles} ;
#        my $path = "$dir/$f";
#        if (-d $path) {
# 	 $dl->insert('end', $f.'/');
#        } elsif( $w -> cget('-files')) {
# 	 if (&{$w->{match}}($f)) {
# 	   if (!defined($accept) || $accept->Call($path)) {
# 	     $seen = $dl->index('end') if ($file && $f eq $file);
# 	     $dl->insert('end', $f)
# 	   }
# 	 }
#        }
#      }
#      closedir(DIR);
#      if ($seen) {
#        $dl->selectionSet($seen);
#        $dl->see($seen);
#      }
#      else {
#        $w->configure(-initialfile => undef) unless $w->cget('-create');
#      }
#    }
#    $w->{DirectoryString} = $dir . '/' . $w->cget('-filter');
#    $w->{'reread'} = 0;
#    $w->Unbusy;
#  }
# }

# sub validateDir
# {
#  my ($cw,$name) = @_;
#  if( ( $cw -> cget( '-connected' ) ) =~ /1/ ) {
#    $name =~ s/^.*\://;
#  }
#  my ($leaf,$base) = fileparse($name);
#  if ($leaf =~ /[*?]/)
#   {
#    $cw->configure('-directory' => $base,'-filter' => $leaf);
#   }
#  else
#   {
#    $cw->configure('-directory' => $name);
#   }
# }

# sub validateFile
# {
#  my ($cw,$name) = @_;
#  my $path = $cw -> {'Configure'}{'-directory'};
#  $cw -> {Selected} = "$path/$name";
# }

# sub Error
# {
#  my $cw  = shift;
#  my $msg = shift;
#  my $dlg = $cw->Subwidget('dialog');
#  $dlg->configure(-text => $msg);
#  $dlg->Show;
# }

sub Show {
    my ($cw,@args) = @_;
    $cw->Popup(@args);
    $cw->focus;
    $cw -> waitVariable(\$cw->{Withdraw});
    $cw -> withdraw;
    return $cw -> {Selected};
}

1;

__END__


=head1 NAME

  SimpleFileSelect -- Easy-to-Use File Selection Widget

=head1 SYNOPSIS

  use Tk::SimpleFileSelect;

  my $fs = $mw -> Tk::SimpleFileSelect();
  my $file = $fs -> Show;

=head2 Options

=over 4

=item -font

Name of the font to display in the directory list and file
name entry.  The default is '*-helvetica-medium-r-*-*-12-*'.

=item -width

Width in character columns of the directory listbox.
The default is 30.

=item -height

Height in lines of the directory listbox.  The default is 14.

=item -directory

=item -initialdir

Path name of initial directory to display.  The default is '.'
(current directory).

=item -files

If non-zero, display files as well as directories.  The default
is 1 (display files).

=item -dotfiles

If non-zero, display normally hidden files that begin with '.'.
The default is 0 (don't display hidden files).

=item -acceptlabel

Text to display in the 'Accept' button to accept a file or
directory selection. Defaults to 'Accept'.  The first character
is underlined to correspond with an Alt- accelerator constructed
with the first letter of the label text.

=item -filter

Display only files matching this pattern.  The default is
'*' (all files).

=head1 DESCRIPTION

Tk::SimpleFileSelect is a easy-to-use file selection widget based
on the Tk::FileSelect widget, but returns only a file name.
It is the job of the calling program perform any operations on the
files named in the SimpleFileSelect's return value.

Clicking in the list box on a file or directory name selects
it and inserts the selected item in the entry box.  Double clicking
on a directory or entering it in the entry box changes to that
directory.

The Show() method causes the FileSelectWidget to wait until a
file is selected in the Listbox, a file name is entered
in the text entry widget, or the 'Close' button is clicked.

The return value is the pathname of a file selected in the
Listbox, or the fully qualified path name of a file given in the
text entry, or an empty string if no file name is specified.

=head1 VERSION INFORMATION

  $Revision: 0.60 $

=head1 COPYRIGHT INFO

Tk::SimpleFileSelect is derived from the Tk::FileSelect widget
in the Perl/Tk library. It is freely distributable and modifiable
under the same conditions as Perl. Please refer to the file
"Artistic" in the distribution archive.

Please submit any bugs to the author, rkiesling@mainmatter.com.

=cut
