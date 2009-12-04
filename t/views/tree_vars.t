#============================================================= -*-perl-*-
#
# t/views/tree_vars.t
#
# Tests for the Template::TT3::View::Tree::Vars module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib   => '../../lib',
    Debug => ':dump :debug';

use Template::TT3::Test 
    tests  => 3,
    debug  => 'Template::TT3::View::Tree::Vars',
    args   => \@ARGV;

use Template3;

my $template = Template3->template( text => <<'EOF' );
Hello [% name %]
[%  a + 10
    user.name
    user.email
    foo.bar.baz
    for user in site.users {
        "Name: $user.name"
        'Email: <a mailto="' ~ user.email ~ '">' ~ user.email ~ '</a>'
    }
=%]
EOF

ok( $template, 'created template' );
my $vars = $template->vars;
ok( $vars, 'got template variables' );

manager->debug( "Got vars: ", main->dump_data($vars) ) if $DEBUG;

my $html = $template->vars_HTML;
ok( $html, 'got template variables as HTML' );

manager->debug( "Got html: ", $html ) if $DEBUG;

