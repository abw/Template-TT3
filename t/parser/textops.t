#============================================================= -*-perl-*-
#
# t/parser/textops.t
#
# Parser tests for textual operators.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test::Parser 
    tests  => 11,
    debug  => 'Template::TT3::Parser Template::TT3::Test::Parser',
    args   => \@ARGV,
    import => 'test_parser';

test_parser(
#    parse_method => 'parse_term',
#    view_method  => 'sexpr',
    debug        => $DEBUG,
);

__DATA__

#------------------------------------------------------------------------
# basic strings
#------------------------------------------------------------------------


#-----------------------------------------------------------------------
# append unary/binary operator
#-----------------------------------------------------------------------

-- test unary append/textify: ~a --
~10
-- expect --
<prefix:<op:~><number:10>>

-- test binary append: a ~ b -- 
1~2
3 ~ 4
-- expect --
<binary:<op:~><number:1><number:2>>
<binary:<op:~><number:3><number:4>>

-- test append associativity: a ~ b ~ c -- 
4 ~ 2 ~ 0
-- expect --
-- collapse --
<binary:
  <op:~>
  <binary:
    <op:~>
    <number:4>
    <number:2>
  >
  <number:0>
>

-- test append equal: a ~= b --
4 ~= 2
-- expect --
<binary:<op:~=><number:4><number:2>>


#-----------------------------------------------------------------------
# other binary operators
#-----------------------------------------------------------------------

-- test equal: a eq b -- 
1 eq 2
-- expect --
<binary:<op:eq><number:1><number:2>>

-- test not equal: a ne b -- 
1 ne 2
-- expect --
<binary:<op:ne><number:1><number:2>>

-- test less than: a lt b -- 
1 lt 2
-- expect --
<binary:<op:lt><number:1><number:2>>

-- test more than: a gt b -- 
1 gt 2
-- expect --
<binary:<op:gt><number:1><number:2>>

-- test less equal: a le b -- 
1 le 2
-- expect --
<binary:<op:le><number:1><number:2>>

-- test more equal: a ge b -- 
1 ge 2
-- expect --
<binary:<op:ge><number:1><number:2>>

-- test compare: a cmp b -- 
1 cmp 2
-- expect --
<binary:<op:cmp><number:1><number:2>>


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

