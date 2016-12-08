use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PipeWrap',
    VERSION_FROM      => 'lib/PipeWrap.pm', # finds $VERSION
    PREREQ_PM         => {
	                      Test::Class::Moose => undef,
			      Log::Log4perl => undef,
			      Moose => undef,
			      
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PipeWrap.pm', # retrieve abstract from module
       AUTHOR         => 'Thomas Hackl, Frank Förster, Simon Pfaff & Aaron Sigmund') : ()),
);
