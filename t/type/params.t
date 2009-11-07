#============================================================= -*-perl-*-
#
# t/type/params.t
#
# Test the Template::TT3::Type::Params module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    debug  => 'Template::TT3::Type::Params',
    args   => \@ARGV,
    tests  => 5;

use Template::TT3::Type::Params qw(PARAMS Params);

ok( 1, 'loaded modules' );

is( PARAMS, 'Template::TT3::Type::Params', 'got PARAMS' );

my $params = Params({ a => 10});
ok( $params, 'created Params' );

$params = PARAMS->new( a => 10 );
ok( $params, 'created PARAMS' );

is( $params->{ a }, 10, 'a is 10' );
    

__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
