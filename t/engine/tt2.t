#============================================================= -*-perl-*-
#
# t/engine/tt2.t
#
# Test script for the Template::TT3:Engine::TT2 module.
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
    lib        => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug   => 'Template::TT3::Engine::TT2 Template::TT2',
    args    => \@ARGV;

# first check to see if Template::TT2 is installed.
BEGIN {
    eval "use Template::TT2";
    skip_all('Template::TT2 not installed') if $@;
}

plan(7);

use Template3 'TT2';
pass( 'loaded Template3 with TT2 engine' );

my $tt2 = Template3->new;
ok( $tt2, 'created Template3 object with TT2 engine' );
is( ref $tt2, 'Template::TT2', 'got Template::TT2 engine' );

my $template = 'Hello [% name %]';
my $output;

$tt2->process(\$template, { name => 'Grandma' }, \$output)
    || die $tt2->error;

is( $output, 'Hello Grandma', 'processed template with TT2 engine' );


#-----------------------------------------------------------------------
# try it with the 'TT2' alias
#-----------------------------------------------------------------------

$tt2 = TT2->new;
ok( $tt2, 'created TT2 engine' );
is( ref $tt2, 'Template::TT2', 'got Template::TT2 engine again' );

$output = '';
$tt2->process(\$template, { name => 'Grandpa' }, \$output)
    || die $tt2->error;

is( $output, 'Hello Grandpa', 'processed template with TT2 engine' );
