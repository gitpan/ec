package EC::Config;

# $cfgfilename = $ENV{'HOME'}.'/.ec/.ecconfig';

                     # Default option settings when config file not found
my $defaults =       # config file; see ~/.ec/.ecconfig for description
  {                  # of each option and valid parameters
   maildomain => 'localhost',
   debug => 0,
   verbose => 0,
   smtpport => 25,
   usesendmail => 0,
   useqmail => 0,
   sendmailprog => '/usr/sbin/sendmail',
   sendmailsetfrom => 0,
   qmail-inject => '',
   sigfile => '.signature',
   usesig => 1,
   mailspooldir => '/var/spool/mail',
   maildir => 'Mail',
   qmailbox => "Mailbox",
   incomingdir => 'incoming',
   trashdir => 'trash',
   helpfile => '.ec/ec.help',
   trashdays => 2,
   pollinterval => 600000,
   senderlen => 20,
   datelen => 26,
   fccfile => '',
   quotestring => '> ',
   senderlen => 25,
   datelen => 21,
   weekdayindate => 1,
   sortfield => 1,
   sortdescending => 0,
   servertimeout => 10,
   headerview => 'brief',
   ccsender => 1,
   browser => '',
   timezone => '-0400',
   gmtoutgoing => 0,
   xterm => 'xterm',
   textfont => '*-courier-medium-r-*-*-14-*',
   headerfont => '*-courier-medium-i-*-*-14-*',
   menufont => '*-helvetica-medium-r-*-*-14-*',
   offline => '',
   };

sub new {
  ($cfgfilename) = @_;
  my $self = &readconfig ($cfgfilename);
  bless $self, 'EC::Config';
  return $self;
}

sub readconfig {
  my ($file) = @_;
  my ($l, @tmpfolders, @cfgfile,$topmaildir);
  @cfgfile = content ($file);
  my %userconfig;
  foreach $l (@cfgfile) {
    if( $l !~ /^\#/) {
      my ($opt, $val) = ($l =~ /^(\S+)\s(.*)$/);
      $val =~ s/[\'\"]//g;
      if( $opt =~ /folder/ ) {
	push @tmpfolders, ($val);
      } elsif ( $opt =~ /filter/ ) {
	push @{$userconfig{'filter'}}, ($val);
      } else {
	$userconfig{$opt} = $val;
      }
      print "config: $opt = ".$userconfig{$opt}."\n" if $debug;
    }
  }
  push @{$userconfig{'folder'}}, ($userconfig{incomingdir});
  push @{$userconfig{'folder'}}, ($userconfig{trashdir});
  push @{$userconfig{'folder'}}, ($_)  foreach( @tmpfolders );
  foreach my $k ( keys %$defaults ) {
    if (! exists $userconfig{$k}) {
      print "Using default value ".$defaults -> {$k}." for $k\n." if $debug;
      $userconfig{$k} = $defaults -> {$k};
    }
  }
  if( ! $cfgfile[0] ) {
    print "Could not open $cfgfilename: using defaults.\n";
    foreach (keys %{$defaults}) {
      $userconfig{$_} = $defaults -> {$_};
      print "config: $_ = ".$userconfig{$_}." from defaults\n" if $debug;
    }
  }
  $userconfig{maildir} = expand_path ($userconfig{maildir});
  verify_path ($userconfig{maildir});
  $userconfig{'helpfile'} = $ENV{HOME}.'/'.$userconfig{'helpfile'};
  $userconfig{'sigfile'} = $ENV{HOME}.'/'.$userconfig{'sigfile'};
  foreach( @{$userconfig{folder}} ) {
    $_ = $userconfig{maildir}.'/'.$_;
    verify_path ($_);
  }
  $userconfig{'incomingdir'} =
    $userconfig{maildir} .'/'.$userconfig{'incomingdir'};
  verify_path ($userconfig{incomingdir});
  $userconfig{'trashdir'}
    = $userconfig{maildir} .'/'.$userconfig{'trashdir'};
  verify_path ($userconfig{trashdir});
  $textfont = $userconfig{'textfont'};
  $headerfont = $userconfig{'headerfont'};
  $menufont = $userconfig{'menufont'};
  return \%userconfig;
}

# prepend $HOME directory to path name in place of ~ or ~/
sub expand_path {
  my ($s) = @_;
  if( $s =~ /^\~/ ) {
    $s =~ s/~//;
    $s = $ENV{'HOME'}."/$s";
  }
  $s =~ s/\/\//\//g;
  return $s;
}

sub verify_path {
  my ($path) = @_;
  if ((not -d $path) and (not -f $path)) {
    die "Verify_path(): Path $path not found: $!\n";
  }
}

sub content {
  my ($file) = @_;
  my ($l, @contents);
  eval {
    open FILE, $file or
      die "Couldn't open $file: ".$!."\n";
    while (defined ($l=<FILE>)) {
      chop $l;
      push @contents, ($l);
    }
    close FILE;
  };
  return @contents;
}

1;
