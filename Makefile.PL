use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "Writing Makefile for Perl version $].\n";

WriteMakefile (NAME => 'EC::About.pm');

WriteMakefile (NAME => 'EC::Attachments.pm');

WriteMakefile (NAME => 'EC::ECConfig.pm');

WriteMakefile (NAME => 'EC::PasswordDialog.pm');

WriteMakefile (NAME => 'Tk::ECWarning.pm');

WriteMakefile (NAME => 'Tk::SimpleFileSelect.pm');

WriteMakefile (NAME => 'EC::Utilities.pm');

if ($] =~ /5.004/) {
	WriteMakefile (
	'NAME'	=> 'ec',
	'VERSION_FROM'	=> 'ec',
	'EXE_FILES'	=> ['ec','encdec'],
	'PREREQ_PM'	=> { 'Tk' => '800.022' },
	);
} else {
	WriteMakefile(
	    'NAME'	=> 'ec',
	    'VERSION_FROM' => 'ec', 
	    'EXE_FILES'  => ['ec', 'encdec'],
	    'PREREQ_PM'  => { 'Tk' => undef },
	    'AUTHOR'        => 'Robert Allan Kiesling <rkiesling@mainmatter.com>',
	);
}


