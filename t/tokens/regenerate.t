#============================================================= -*-perl-*-
#
# t/tokens/regenerate.t
#
# Check that we can regenerate the template source from the tokens.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests  => 8,
    debug  => 'Template::TT3::Generator::Tokens::Source',
    args   => \@ARGV,
    import => 'test_regen';
    
test_regen();

__END__

-- test static text --
Hello World

-- test text with simple tag --
Hello [% name or 'World' %]

-- test tag with chomp options --
Hello [% name or 'World' -%]
Foo [%- bar %]
Wiz [% waz ~%]

   [% blah =%]
Hello

-- test control tags --
foo [? TAGS '<* *>' ?]
[?- TAGS.control '<? ?>' =?]
wiz wiz 
    <?~ TAGS.all off ~?>
    <? THIS IS TEXT ?>
    [? SO IS THIS   ?]
end

-- test simple comment tag --
[# foo #]

-- test simple comment tag with post-chomp --
[# foo -#]

-- test simple comment tag with post-chomp and something to chomp --
[# foo -#]   foo

-- test complex comment tags --
foo [# blah blah #]
hello 
[#  this is a multi-line comment
    with embedded [% tags %] and 
    other "things"
    NOTE: don't put '#' at start of line
    because the test manager assumes it's a 
    comment and strips it out of the input
    before TT even gets a change to look 
    at it  #]
blah
   [#~ foo ~#]
      bar


