#============================================================= -*-perl-*-
#
# t/engine/template3.t
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
    debug => 'Template3',
    args  => \@ARGV,
    tests => 15;

use Template3;

my $tdir = Bin->dir('templates');
my $tt3  = Template3->new( template_path => $tdir );
ok( $tt3, 'created template engine' );


#-----------------------------------------------------------------------
# process() with different input types
#-----------------------------------------------------------------------

test_process_input(                     # input filename in templates dir
    'women_children.tt3',               
    { when => 'First' }, 
    'Women and Children First'
);

test_process_input(                     # [file => $name]
    [ file => 'women_children.tt3' ],   
    { when => 'Last' }, 
    'Women and Children Last'
);

test_process_input(                     # {file => $name}
    { file => 'women_children.tt3' },   
    { when => 'Together' }, 
    'Women and Children Together'
);

test_process_input(                     # {type => 'file', name => $name}
    { type => 'file', 
      name => 'women_children.tt3' },
    { when => 'for Breakfast' }, 
    'Women and Children for Breakfast'
);

my $text = 'Fair [% alert %]';
test_process_input(                     # reference to template text
    \$text,                             
    { alert => 'Warning' }, 
    'Fair Warning'
);

test_process_input(                     # [text => $text] 
    [ text => $text ],                  
    { alert => 'Error' }, 
    'Fair Error'
);
test_process_input(                     # {text => $text} 
    { text => $text },                  
    { alert => 'Core Dump' }, 
    'Fair Core Dump'
);

my $code = sub {
    my $context = shift;
    return "Diver " . $context->var('dir')->value;
};
test_process_input(                     # reference to a subroutine
    $code,                              
    { dir => 'Down' }, 
    'Diver Down'
);
test_process_input(                     # [code => $code] subroutine
    [ code => $code ],
    { dir => 'Up' }, 
    'Diver Up'
);
test_process_input(                     # { code => $code } subroutine
    { code => $code },                  
    { dir => 'Left' }, 
    'Diver Left'
);

test_process_input(                     # reference to an IO::File
    $tdir->file('1984.tt3')->open,      
    { number => 'Four' }, 
    'Nineteen Eighty Four'
);
test_process_input(                     # [ handle => $fh ] IO::File
    [ handle => $tdir->file('1984.tt3')->open ],
    { number => 'Five' }, 
    'Nineteen Eighty Five'
);
test_process_input(                     # [ fh => $fh ] IO::File
    [ fh => $tdir->file('1984.tt3')->open ],
    { number => 'Six' }, 
    'Nineteen Eighty Six'
);
test_process_input(                     # { fh => $fh } IO::File
    { fh => $tdir->file('1984.tt3')->open },
    { number => 'Seven' }, 
    'Nineteen Eighty Seven'
);



sub test_process_input {
    my ($input, $vars, $expect, $message) = @_;
    is( 
        $tt3->process($input, $vars),
        $expect,
        $message || $expect
    );
}
