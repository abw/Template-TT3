package Template::TT3::Grammar::Control;

use Template::TT3::Elements::Core;
use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Grammar';


our $SYMBOLS  = [
    [ '.'           => op_dot           => 340,   0 ],
    [ '*'           => num_multiply     => 280,   0 ],
    [ '='           => assign           => 220,   0 ],
    [ '=>'          => op_pair          => 220,   0 ],
    [ '('           => con_parens       =>   0,   0 ],
    [ '['           => con_list         =>   0,   0 ],
    [ '{'           => con_hash         =>   0,   0 ],
    [ ')'           => terminator       =>   0,   0 ],
    [ ']'           => terminator       =>   0,   0 ],
    [ '}'           => terminator       =>   0,   0 ],
    [ ','           => separator        =>   0,   0 ],
    [ ';'           => delimiter        =>   0,   0 ],
    [ ':'           => terminator       =>   0,   0 ],
    [ 'TAGS'        => ctr_tags         =>   0,   0 ],
    [ 'HTML'        => ctr_html         =>   0,   0 ],
    [ 'COMMANDS'    => ctr_commands     =>   0,   0 ],
];

1;

__END__

=head1 DESCRIPTION

This grammar implements a limited set of elements for parsing control tags.  

e.g.

    TAGS '<* *>'
    TAGS ['<*', '*>']
    TAGS = '<* *>'
    TAGS = ['<*', '*>']
    TAGS.inline '<* *>'
    TAGS.inline = ['<*', '*>']
    TAGS.* off
    TAGS {
        inline = off
        outline => '...'
    }
    
