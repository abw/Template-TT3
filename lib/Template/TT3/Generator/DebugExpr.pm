package Template::TT3::Generator::DebugExpr;

use Template::TT3::Class
    version  => 2.7,
    debug    => 0,
    base     => 'Template::TT3::Generator::Debug';


sub generate_binop {
    my ($self, $op, $lhs, $rhs) = @_;

#    $self->debug("BINOP: [$op] [$lhs] [$rhs]");

    # Bugger - there's a problem using elements for both tokens and 
    # expresssions.  When inspecting a token list, we want a dotop to 
    # render as '.', but when inspecting an expression tree, we want a 
    # dotop to render as 'lhs.rhs'.  I guess we have to use different 
    # generators for token and expression views.

    return 
        '<binop:'
      . join(
            $op,
            map { $_->generate($self) }
            $lhs, $rhs
         )
       . '>';
}


sub generate_prefix {
    my ($self, $op, $rhs) = @_;
    return "<prefix:$op:" . $rhs->generate($self) . '>';
}

sub generate_postfix {
    my ($self, $op, $lhs) = @_;
    return "<postfix:$op:" . $lhs->generate($self) . '>';
}

sub generate_do {
    my ($self, $keyword, $block) = @_;
    return "<do:" . $block->generate($self) . '>';
}

sub generate_block {
    my ($self, $exprs) = @_;
    return "<block:" 
        . join("\n  ", map { $_->generate($self) } @$exprs)
        . '>';
}

    

1;
