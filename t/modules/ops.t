#============================================================= -*-perl-*-
#
# t/modules/ops.t
#
# Test the Template::TT3::Ops module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 9,
    debug => 'Template::TT3::Ops',
    args  => \@ARGV;

use Template::TT3::Ops;
use constant {
    OPS => 'Template::TT3::Ops',
};

ok( 1, 'loaded ops' );

my $ops = OPS->new;
ok( $ops, 'created ops object' );

my $ctors = $ops->constructors;
ok( $ctors, 'got constructors' );

my $op = $ctors->{ number }->(10);
ok( $op, 'got number op' );
is( $op->value, 10, 'op value is 10' );

my $n1 = $ops->op( number => 42 );
is( $n1->value, 42, 'n1 value is 42' );

my $n2 = $ops->op( number => 69 );
is( $n2->value, 69, 'n2 value is 69' );

my $add = $ops->op( add => '+', 3, $n1, $n2 );
is( $add->value, 111, 'addition: 42 + 69 = 111' );

my $sub = $n2->numerical_op( subtract => '-', 4, $n1 );
is( $sub->value, 27, 'subtraction: 69 - 42 = 27' );

