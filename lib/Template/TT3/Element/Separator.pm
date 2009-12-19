package Template::TT3::Element::Separator;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element';


sub parse_expr {
    my ($self, $token, @args) = @_;
    $$token = $self->[NEXT] if $token;
    $self->[NEXT]->parse_expr($token, @args);
}


sub skip_separator {
    $_[SELF]->next_skip_ws( $_[CONTEXT] )
            ->skip_separator( $_[CONTEXT] );
}


sub skip_delimiter {
    $_[SELF]->next_skip_ws( $_[CONTEXT] )
            ->skip_delimiter( $_[CONTEXT] );
}


1;
