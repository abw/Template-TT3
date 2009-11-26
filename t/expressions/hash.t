#============================================================= -*-perl-*-
#
# t/expressions/hash.t
#
# Test script for { hash => value } expressions.
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
    tests   => 13,
    debug   => 'Template::TT3::Element::Construct::Hash 
                Template::TT3::Element::Construct::List
                Template::TT3::Element::Sigil::Hash',
    args    => \@ARGV,
    import  => 'test_expressions callsign';

our $vars = {
    %{ callsign() },
    
    xyz_list => sub {
        my $list = [ x => 10, y => 20, z => 30 ];
        return wantarray
            ? @$list
            :  $list;
    },

    abc_hash => sub {
        return { x => 10, y => 20, z => 30 };
    },
};

test_expressions(
    block     => 1,
    debug     => $DEBUG,
    variables => $vars,
);

__DATA__

-- test empty hash --
{ }.keys.join
-- expect --

-- test hash constructor --
hash = {
    a = 10
    b = 20
    c = 30
}
hash.keys.sort.join
-- expect --
a b c

-- test hash constructor with expressions --
hash = {
    x = 5 * 2
    y = (2 + 2) * (4 + 1)
    z = 90 / 3
}
hash.keys.sort.join "\n"
'x: ' hash.x "\n"
'y: ' hash.y "\n"
'z: ' hash.z "\n"
-- expect --
x y z
x: 10
y: 20
z: 30

-- test inline hash creator --
{a=10, b=20, c=30}.keys.sort.join
-- expect --
a b c

-- test arrows --
hash = {
    e   => 2.718
    pi  => 3.142
    phi => 1.618
}
hash.keys.join
-- expect --
e phi pi

-- test commas --
hash = {
    e   => 2.718,
    pi  => 3.142,,,
    phi => 1.618,,,,,
}
hash.keys.join
-- expect --
e phi pi

-- test semi-colons --
hash = {
    e   => 2.718;
    pi  => 3.142;
    phi => 1.618;
}
hash.keys.join
-- expect --
e phi pi

-- test comments --
hash = {
    e   => 2.718    # this relates to growth
    pi  => 3.142    # this relates to circles
    phi => 1.618    # this relates to ratios
}
hash.keys.join
-- expect --
e phi pi



#-----------------------------------------------------------------------
# populate with results expanded from a subroutine call.
#-----------------------------------------------------------------------

-- test populate sub --
hash = {
    a = 10
    @xyz_list
}
hash.keys.sort.join
-- expect --
a x y z


#-----------------------------------------------------------------------
# hash expansion
#-----------------------------------------------------------------------

-- test hash merging --
h1 = { a => 10, b => 20 }
h2 = { x => 30, y => 40 }
h3 = { %h1, %h2 };
h3.keys.sort.join "\n"
h3.values.sort.join
-- expect --
a b x y
10 20 30 40

-- test list as hash --
list = [a => 10, b => 20];
#'type: ' list.type ' / ' list.ref "\n"
hash = { %list };
hash.keys.sort.join;
-- expect --
a b

-- test list with odd number of items --
list = [a => 10, 20];
hash = { %list };
hash.keys.sort.join;
-- expect --
<ERROR:Cannot make pairs from an odd number (3) of items: list>

-- test single item as hash --
twenty = 20;
hash = { %twenty };
hash.keys.sort.join ': ' hash.twenty
-- expect --
<ERROR:Cannot make pairs from an odd number (1) of items: twenty>
#twenty: 20



__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
# Textmate: is a cold slice of watermelon on a hot day

