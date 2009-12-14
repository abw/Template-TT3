#============================================================= -*-perl-*-
#
# t/modules/template3.t
#
# Test the Template3 module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
#    debug => 'Template3 Template::TT3::Templates',
    debug => 'Template::TT3::Engine::TT3 Template::TT3::Services',
    args  => \@ARGV,
    tests => 6;

use Template3;


#-----------------------------------------------------------------------
# object methods
#-----------------------------------------------------------------------

my $tt3 = Template3->new;
ok( $tt3, 'created template engine' );
is( ref $tt3, 'Template::TT3::Engine::TT3', 'Template3() returns TT3 engine' );


my $fill = $tt3->template( text => 'Hello [% name %]' )->fill( name => 'Badger' );
is( $fill, 'Hello Badger', 'filled template' );


#-----------------------------------------------------------------------
# class methods
#-----------------------------------------------------------------------

Template3->config(
    template_path => Bin->dir('templates')
);

$fill = Template3->fill(
    text => 'Goodbye [% name %]',
    data => { name => 'Cruel World' }
);
is( $fill, 'Goodbye Cruel World', 'filled template text via class method');

$fill = Template3->fill(
    file => 'hello.tt3',
    data => { name => 'Badger' }
);
is( $fill, 'Hello Badger!', 'filled template file via class method');


#-----------------------------------------------------------------------
# process() with different input types
#-----------------------------------------------------------------------

my $input = 'Van [% dir %]';
test_process_input(\$input, { dir => 'Halen' }, 'Van Halen');

sub test_process_input {
    my ($input, $vars, $expect, $message) = @_;
    is( 
        Template3->process($input, $vars),
        $expect,
        $message || $expect
    );
}

# there are more process() tests in t/engine/template3.t
