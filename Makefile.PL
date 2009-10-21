use ExtUtils::MakeMaker;

my %opts = (
    'NAME'         => 'Template::TT3',
    'DISTNAME'     => 'Template-TT3',
    'VERSION'      => 3.00,
#    'VERSION_FROM' => 'lib/Template/TT3.pm',
    'PMLIBDIRS'    => [ 'lib' ], 
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
    'test'         => {
        TESTS      => 't/*.t t/*/*.t',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>';
    $opts{ ABSTRACT } = 'comprehensive template processing system',
}

WriteMakefile( %opts );

package YOURMY;

sub install {
    return <<'EOF';
install :
	@echo "Don't be silly!  This isn't even alpha code yet"

EOF
}

