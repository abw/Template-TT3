#============================================================= -*-perl-*-
#
# t/scanner/tags.t
#
# Test the TAGS scanner directive for switching tags styles.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

#use Badger::Debug 
#    modules => 'Badger::Factory';

use Badger 
    lib => '../../lib';

use Template::TT3::Test 
    skip  => 'Not working',
    tests => 6,
    debug => 'Template::TT3::Scanner',
    args  => \@ARGV;

use Template::TT3::Scanner;
use Template::TT3::Tag::Inline;
use Template::TT3::Tag::Scanner;
use Template::TT3::Generator;
use constant {
    SCANNER   => 'Template::TT3::Scanner',
    ITAG      => 'Template::TT3::Tag::Inline',
    STAG      => 'Template::TT3::Tag::Scanner',
    GENERATOR => 'Template::TT3::Generator',
};


#-----------------------------------------------------------------------
# setup
#-----------------------------------------------------------------------

my $itag = ITAG->new(
    start => '[%',
    end   => '%]',
);
ok( $itag, 'created inline tag' );

my $stag = STAG->new(
    start => '[?',
    end   => '?]',
);
ok( $stag, 'created scanner tag');

my $scanner = SCANNER->new( 
    tags => [ $itag, $stag ],
);
ok( $scanner, 'created scanner' );

my $gen = GENERATOR->new;
ok( $gen, 'created generator');


#-----------------------------------------------------------------------
# scan for tokens
#-----------------------------------------------------------------------

my $tokens = $scanner->scan(<<'EOF');
some text
[% var %]
more text
[? TAGS off ?]
even more text
EOF

ok( $tokens, "got tokens: $tokens" );
is( $tokens->size, 15, 'got 15 tokens' );

my $token = $tokens->first->skip_ws;

print "SKIPPING...\n";

while ($token) {
    print "NON-WS: ", $token->generate($gen), "\n";
    $token = $token->next_skip_ws;
}


__END__
print "-----\n";
print $tlist->generate($gen), "\n\n";
print "=====\n\n";

my $first = $tlist->first->skip_ws;

while ($first) {
    print "NON-WS: ", $first->generate($gen), "\n";
    $first = $first->next_skip_ws;
}

__END__
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
