use Badger lib => '../../lib';

use Template::TT3::Test 
    tests => 1,
    debug => 'Template::TT3::Scanner',
    args  => \@ARGV;

use Template::TT3::Scanner;
use Template::TT3::Tag;
use constant {
    SCANNER => 'Template::TT3::Scanner',
    TAG     => 'Template::TT3::Tag',
};

my $dirtag = TAG->new(
    start => '[%',
    end   => '%]',
    keywords => {
        foo => 'FOO',
        bar => 'BAR',
    }
);

my $vartag = TAG->new(
    start => '${',
    end   => '}',
);

my $scanner = SCANNER->new( 
    tags => [ $dirtag, $vartag ],
);
ok( $scanner, 'created scanner' );

my $tokens = $scanner->scan(<<'EOF');
hello world
this is some [% var %] text
[% foo bar # nothing to add here %]
more text
${x y z # this is a comment
        # that goes on for 
        # several lines }
the end 
EOF

ok( $tokens, "got tokens: $tokens" );
print "-----\n";
#print join(', ', @$tokens);
print display($tokens);



sub display {
    my $tokens = shift;
    join(
        "\n",
        map { 
            my $text = $_->[1];
            $text =~ s/\n/\\n/g;
            "[$_->[0] => $text]" 
        }
        @$tokens
    );
}
