use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::quotas',
    'VERSION_FROM'	=> 'quotas.pm',
    'PREREQ_PM'		=> {}, 
    ( 
        $] >= 5.005
          ? (ABSTRACT_FROM => 'quotas.pm',
             AUTHOR        => 'Charles A Morris')
          : ()
    ),
);
