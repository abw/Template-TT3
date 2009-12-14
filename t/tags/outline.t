#============================================================= -*-perl-*-
#
# t/tags/outline.t
#
# Test script for the outline tag
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    tests   => 10,
    debug   => 'Template::TT3::Tag::Outline Template::TT3::Scanner',
    args    => \@ARGV,
    import  => 'test_expect callsign :all';

$Badger::Debug::MAX_TEXT = 1024;

our $vars = callsign;

#-----------------------------------------------------------------------
# There's some tricky regex magic required to allow outline tags to 
# match comments and whitespace to the end of line without consuming
# the end-of-tag newline character
#-----------------------------------------------------------------------

use Template::TT3::Tag::Outline;
use constant OUTLINE => 'Template::TT3::Tag::Outline';

my $outline = OUTLINE->new;
my $comment = $outline->{ match_comment    };
my $wspace  = $outline->{ match_whitespace };
my $at_end  = $outline->{ match_at_end     };

my $input = "# hello\n";
ok( $input =~ /$comment/cg, 'comment matches' );
ok( $input =~ /\G\n/, 'matched newline after comment' );

$input = "   \n";
ok( $input =~ /$wspace/cg, 'whitespace matches' );
ok( $input =~ /\G\n/, 'matched newline after whitespace' );

$input = "\n";
ok( $input =~ /$at_end/cg, 'matched newline at end' );

$input = "";
ok( $input =~ /$at_end/cg, 'matched end at end' );


#-----------------------------------------------------------------------
# run the tests in the __DATA__ section
#-----------------------------------------------------------------------

test_expect(
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test outline --
before
%% a
after
-- expect --
before
alphaafter

-- test multi outline --
before
%% a b
%% c
after
-- expect --
before
alphabravocharlieafter

-- test if outline --
alpha
%% if 1
bravo
%% end
charlie
-- expect --
alpha
bravo
charlie

-- test if outline with trailing spaces and comments --
# outline tags currently consume the newline end-of-tag token when they
# much whitespace and comments.
%% a
%% if 1        # this is a comment
bravo
# there are trailing spaces on the end of the next line
%% end   
charlie
-- expect --
alphabravo
charlie
