package EC::Attachments;

$VERSION=0.10;

my $base64enc = 'encdec';

my $outgoing_mime_boundary = "_----------------------------------";

my @default_mime_headers = ('MIME-Version: 1.0',
                            'Content-Type: text/plain; charset="us-ascii"',
                            'Content-Transfer-Encoding: 7bit');

my @base64_headers = ('MIME-Version: 1.0',
                      'Content-Type: multipart/mixed; boundary="'.
                         $outgoing_mime_boundary.'"', 
                      'Content-Transfer-Encoding: base64');

my @base64_attachment_header = ('Content-Type: application/octet-stream; name=',
                      'Content-Transfer-Encoding: base64',
                      'Content-Disposition: filename=');

sub attachment_filenames {
    my ($msg) = @_;
    my (@filenames, $name);
    my $boundary = &mime_boundary ($msg);
    my @msglines = split /\n/, $msg;
    foreach my $l (@msglines) {
	if ($l =~ /filename\=/si) {
	    ($name) = ($l =~ /filename\=\"(.*?)\"/si);
	    push @filenames, ($name);
	}
    }
    return @filenames;
}

sub mime_boundary {
    my ($msg) = @_;
    my ($boundary) = ($msg =~ /boundary=(.*?)\n/si);
    $boundary =~ s/\"//g;
    return $boundary;
}

sub save_attachment {
    my ($msg, $attachmentfilename, $ofilename) = @_;
    my $boundary = &mime_boundary ($msg);
    # RFC 2046 - attachment body separated from preceding boundary
    # and attachment headers by two CRLFs - translated to Unix line
    # endings here.  Boundary at the end of the attachment is preceded
    # in practice by two newlines.
    my ($cstr) = ($msg =~ 
      m"filename=\"$attachmentfilename\".*?\n\n(.*?)\n+--$boundary"smi);
    open TMP, ">/tmp/ec-tmp-$$" or warn "Couldn't open temp file: $!\n";
    print TMP $cstr;
    close TMP;
    `$base64enc -d -b </tmp/ec-tmp-$$ >$ofilename 2>/tmp/ec-error-$$`;
    open ERROR, "/tmp/ec-error-$$" or warn
	"Couldn't open /tmp/ec-error-$$: $!\n";
    if (scalar (grep (/base64/, <ERROR>)) != 0) {
	unlink "$ofilename";
	open TMP, "/tmp/ec-tmp-$$" or
	    warn "Couldn't open /tmp/ec-tmp-$$ for copying: $!\n";
	open OFILE, ">$ofilename" or 
	    warn "Couldn't open $ofilename for direct write: $!\n";
	my $line;
	while (defined ($line = <TMP>)) { print OFILE $line }
	close TMP;
	close OFILE;
	close ERROR;
    }
    unlink "/tmp/ec-error-$$";
    unlink "/tmp/ec-tmp-$$";
}

### Required plain and base64 message header fields.

sub default_mime_headers { return @default_mime_headers }

sub base64_headers { return @base64_headers }


### Headers for each attachment

#
# This gets inserted before the message text so no 
# additional formatting is necessary.
#
sub text_attachment_header {
    return ( "",
	     "This is a multi-part message in MIME format.",
	     '--'.$outgoing_mime_boundary,
	     "Content-Type: text/plain; charset=us-ascii",
	     "Content-Transfer-Encoding: 7bit",
	     "");
}

sub format_attachment {
    my ($filepath) = @_;
    my (@formatted,$basename);
    ($basename) = ($filepath =~ /.*\/(.*)/si);
    push @formatted, ('--'.$outgoing_mime_boundary,
		  "Content-Type: application/octet-stream; name=\"$basename\"",
		  "Content-Transfer-Encoding: base64",
		  "Content-Disposition: attachment; filename=\"$basename\"");
    push @formatted, ('');

    open ENC, "$base64enc -e -b <$filepath|" or
	    &show_warn_dialog ($mw, $warndialog,
                               -message => "Couldn't encode $fullname: $!\n");
    while ( defined ($line = <ENC>) ) {
	chomp $line;
	push @formatted, ($line);
    }
    close ENC;
    push @formatted, ('');
    return @formatted;
}

sub outgoing_mime_boundary {
    return $outgoing_mime_boundary;
}

1;
