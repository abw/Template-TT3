package Template::TT3::Element::Whitespace;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'whitespace',
    alias     => {
        skip_ws => 'next_skip_ws',
    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    shift->next_skip_ws( $_[0] )
         ->skip_delimiter( @_ );
}


sub parse_expr {
    # we can always skip whitespace to get to an expression
    shift->next_skip_ws( $_[0] )
         ->parse_expr( @_ );
}


sub parse_body {
    # same for a block
    shift->next_skip_ws( $_[0] )
         ->parse_body( @_ );
}


sub parse_pair {
    # ditto pair
    shift->next_skip_ws( $_[0] )
         ->parse_pair( @_ );
}

1;

