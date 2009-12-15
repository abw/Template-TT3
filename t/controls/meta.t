#============================================================= -*-perl-*-
#
# t/controls/meta.t
#
# Test script for META control directive.
#
# Run with -h option for help.
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
    tests   => 4,
    debug   => 'Template::TT3::Tag',
    args    => \@ARGV,
    import  => 'test_expect callsign :all';

use Template3;

my $template = Template3->template( text => <<'EOF' );
[? META title = 'Hello World' author = 'Andy Wardley' -?]
The title of this template is [% template.title %]
EOF

ok( $template, "compiled template: $template" );
my $output = Template3->process( $template );
is( $output, 
    "The title of this template is Hello World\n", 
    'got template title in output' 
);

my $template2 = Template3->template( text => <<'EOF' );
[? META { title = 'Hello World' author = 'Andy Wardley' } -?]
The author of this template is [% template.author %]
EOF

ok( $template2, "compiled template: $template2" );
$output = Template3->process( $template2 );
is( $output, 
    "The author of this template is Andy Wardley\n", 
    'got template author in output' 
);

exit;

test_expect(
    debug     => $DEBUG,
    variables => callsign,
);

__DATA__

-- test one --
Hello [% a %]
-- expect --
Hello alpha

-- test tags invalid --
[? TAGS invalid -?]
Hello World
-- expect --
<ERROR:Undefined value returned by expression: invalid>
#<ERROR:Undefined value returned by TAGS expression: invalid>

-- test tags single string --
BEFORE
[? TAGS '<* *>' -?]
Hello <* a *>
-- expect --
BEFORE
Hello alpha

-- test tags list ref --
[? TAGS ['<*' '*>'] -?]
Hello <* b *>
-- expect --
Hello bravo

-- test tags equals string --
[? TAGS = '<* *>' -?]
Hello <* c *>
-- expect --
Hello charlie

-- test tags equals list ref --
[? TAGS = ['<*' '*>'] -?]
Hello <* d *>
-- expect --
Hello delta

-- test tags are --
[? TAGS are ['<*' '*>'] -?]
Hello <* e *>
-- expect --
Hello echo

-- test tags off --
[? TAGS off -?]
Hello [% f %]
-- expect --
Hello [% f %]

-- test tags off/on --
[? TAGS off -?]
Hello [% f %]
[? TAGS on -?]
Hello [% f %]
-- expect --
Hello [% f %]
Hello foxtrot

-- test tags get restored to previous state --
[? TAGS '<* *>' -?]
<* h.ucfirst *> California
[? TAGS off -?]
<* h.ucfirst *> California
[? TAGS on -?]
<* h.ucfirst *> California
-- expect --
Hotel California
<* h.ucfirst *> California
Hotel California

-- test multiple tags --
[? TAGS {
     inline  = '<* *>'
     comment = '<# #>'
   }
-?]
Hello [% i %]
Hello <* i *>
Hello [# i #]
Hello <# i #>!
-- expect --
Hello [% i %]
Hello india
Hello [# i #]
Hello !

-- test dotted inline tags --
[? TAGS.inline '<* *>' -?]
Romeo and [% j.ucfirst %]
Romeo and <* j.ucfirst *>
-- expect --
Romeo and [% j.ucfirst %]
Romeo and Juliet

-- test dotted comment tags --
[? TAGS.comment '<* *>' -?]
Romeo and [% j.ucfirst %] are lovers
Romeo and <* j.ucfirst *> are lovers
-- expect --
Romeo and Juliet are lovers
Romeo and  are lovers

-- test tags reset tags --
Romeo and [% j.ucfirst %] are lovers
Romeo and <* j.ucfirst *> are lovers
-- expect --
Romeo and Juliet are lovers
Romeo and <* j.ucfirst *> are lovers

-- test TAGS.all --
[? TAGS.all off -?]
[% k %] [? k ?] [# k #]
%% k
-- expect --
[% k %] [? k ?] [# k #]
%% k

-- test dotted tags with invalid name --
[? TAGS.cheese '<* *>' -?]
Romeo and [% j.ucfirst %] are lovers
-- expect --
<ERROR:Invalid tags specified: cheese>

    

