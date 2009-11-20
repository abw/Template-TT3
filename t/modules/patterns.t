#============================================================= -*-perl-*-
#
# t/module/patterns.t
#
# Test the Template::TT3::Patterns module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 11,
    debug => 'Template::TT3::Patterns Badger::Exporter',
    args  => \@ARGV;

use Template::TT3::Patterns ':punctuate $INTEGER $SQUOTE';

#-----------------------------------------------------------------------
# test that Template::Patterns is exporting regexen for pattern matching
#-----------------------------------------------------------------------

ok(1, 'loaded modules');
ok( defined $SEPARATOR, '$SEPARATOR is defined' );
ok( defined $DELIMITER, '$DELIMITER is defined' );
like( ',', $SEPARATOR, 'separator match' );
like( ';', $DELIMITER, 'delimiter match' );
unlike( '.', $SEPARATOR, 'separator not match' );
unlike( '|', $DELIMITER, 'delimiter not match' );


#-----------------------------------------------------------------------
# check that they work
#-----------------------------------------------------------------------

like( 11, $INTEGER, '11 is an integer' );
like( 11, qr/^$INTEGER$/, '11 is still an integer' );


#-----------------------------------------------------------------------
# test that tricky single quote matching regex.
#-----------------------------------------------------------------------

my $text = q{'single quote with \\ escaped backslash'};
ok( $text =~ $SQUOTE, "matched: $2" );

$text = q{'single quote with escaped backslash at end \\'};
ok( $text =~ $SQUOTE, "matched: $2" );



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
