#============================================================= -*-perl-*-
#
# t/parser/commands.t
#
# Parser tests for commands.  
#
# Run with '-h' option for help with command line arguments.
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
    tests  => 7,
    debug  => 'Template::TT3::Tag Template::TT3::Element',
    args   => \@ARGV,
    import => 'test_parser';

test_parser(
    debug => DEBUG,
);

__DATA__

-- test naked if --
-- block --
if item < 5
   item * 2
-- expect --
<if:
  <expr:
    <binary:<op:<><variable:item><number:5>>
  >
  <body:
    <binary:<op:*><variable:item><number:2>>
  >
>

-- test naked for/if --
-- block --
for 5
   if item < 5
      item * 2
-- expect --
<for:
  <expr:
    <number:5>
  >
  <body:
    <if:
      <expr:
        <binary:<op:<><variable:item><number:5>>
      >
      <body:
        <binary:<op:*><variable:item><number:2>>
      >
    >
  >
>


-- test list generator with single block expressions --
-- block --
[   for [1, 2, 3, 4, 5, 6] 
        if item < 5
            item * 2
]
-- expect --
<list:
  <for:
    <expr:
      <list:
        <number:1>
        <number:2>
        <number:3>
        <number:4>
        <number:5>
        <number:6>
      >
    >
    <body:
      <if:
        <expr:
          <binary:<op:<><variable:item><number:5>>
        >
        <body:
          <binary:<op:*><variable:item><number:2>>
        >
      >
    >
  >
>


-- test list generator with side effect expressions --
-- block --
[  item * 2
     if item < 5
       for [1, 2, 3, 4, 5, 6] 
]
-- expect --
<list:
  <for:
    <expr:
      <list:
        <number:1>
        <number:2>
        <number:3>
        <number:4>
        <number:5>
        <number:6>
      >
    >
    <body:
      <if:
        <expr:
          <binary:<op:<><variable:item><number:5>>
        >
        <body:
          <binary:<op:*><variable:item><number:2>>
        >
      >
    >
  >
>

-- test filename: foo --
fill foo
-- expect -- 
<fill:<filename:foo>>

-- test filename: foo.tt3 --
fill foo.tt3
-- expect -- 
<fill:<filename:foo.tt3>>

-- test filename: foo/bar.tt3 --
fill foo/bar.tt3
-- expect -- 
<fill:<filename:foo/bar.tt3>>



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


