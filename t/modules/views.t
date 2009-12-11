#============================================================= -*-perl-*-
#
# t/modules/views.t
#
# Test the Template::TT3::Views module.
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
    debug => 'Badger::Factory Template::TT3::Views',
    args  => \@ARGV,
    tests => 4;

use Template::TT3::Views;
use constant VIEWS => 'Template::TT3::Views';

my $tok_dbg = VIEWS->view('tokens.debug');
ok( $tok_dbg, 'got tokens debug view' );
is( 
    ref $tok_dbg, 
    'Template::TT3::View::Tokens::Debug', 
    'isa Template::TT3::View::Tokens::Debug' 
);

my $tree_html = VIEWS->view('tree.HTML');
ok( $tree_html, 'got tree html view' );
is( 
    ref $tree_html, 
    'Template::TT3::View::Tree::HTML', 
    'isa Template::TT3::View::Tree::HTML' 
);

__END__
my $tok_html = VIEWS->view('tokens.HTML');
ok( $tok_html, 'got tokens HTML generator' );
is( 
    ref $tok_html, 
    'Template::TT3::View::Tokens::HTML', 
    'isa Template::TT3::View::Tokens::HTML' 
);
