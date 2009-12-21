#============================================================= -*-perl-*-
#
# t/modules/variables.t
#
# Test the Template::TT3::Variables module.
#
# Run with the -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib';
    
use Template::TT3::Test 
    debug => 'Template::TT3::Variables',
    args  => \@ARGV,
    tests => 3;

use Badger::Debug ':all';
use Template::TT3::Variables;
use constant VARS => 'Template::TT3::Variables';

my $ctors = VARS->constructors;
ok( $ctors, 'got constructors' );

$ctors = VARS->constructors(
    undef => 'missing',
    text => {
        foo => sub { 'FOO' },
        bar => sub { 'BAR' },
    },
    'Wiz::Bang' => {
        '*'   => 0,
        'foo' => 1,
        'bar' => sub { 'PRETENDING TO BE BAR' },
    }
);

ok( $ctors, 'got constructors with custom types' );
my $type = $ctors->{'Wiz::Bang'};
ok( $type, 'got custom Wiz::Bang type' );

