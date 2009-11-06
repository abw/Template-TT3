#-----------------------------------------------------------------------
# Template::TT3::Element::Literal - base class for literal elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Literal;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots';


sub text {
    $_[0]->[TEXT];
}

sub value {
    $_[0]->[TEXT];
}

sub values {
    $_[0]->[TEXT];
}

sub text_element {
    $_[0];
}

sub generate {
    $_[1]->generate_literal(
        $_[0]->[TEXT]
    );
}

sub dot_op {
    my ($self, $text, $pos, $rhs) = @_;
    $self->[META]->[ELEMS]->op(
        # $rhs should call method to resolve it as a dot-right-able item
        # in the same way that numerical_op() in T...Op::Number calls 
        # $rhs->number_op
        dot => $text, $pos, $self, $rhs
    );
}



#-----------------------------------------------------------------------
# Template::TT3::Element::Word - literal word elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Word;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_word(
        $_[0]->[TEXT],
    );
}

sub as_expr {
    shift->become('variable')->as_expr(@_);
}

sub as_dotop {
    $$_[1] = $_[0]->[NEXT];
    return $_[0];
}


#-----------------------------------------------------------------------
# Template::TT3::Element::Keyword - literal keyword elements
#-----------------------------------------------------------------------

package Template::TT3::Element::Keyword;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_keyword(
        $_[0]->[TEXT],
    );
}


package Template::TT3::Element::Punctuation;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots';

sub as_expr {
    return undef;
}

sub generate {
    $_[1]->generate_punctuation(
        $_[0]->[TEXT]
    );
}


package Template::TT3::Element::Terminator;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation',
    constants => ':elem_slots',
    constant  => {
        is_terminator => 1,
    };

#sub as_expr {
#    shift->next_skip_ws($_[0])->as_expr(@_);
#}

sub as_block {
    my ($self, $token, $scope, $prec) = @_;
    my (@exprs, $expr);

    # advance past terminator token
#    $$token = $self->[NEXT];
#    $self->next_skip_ws($token);

    while ($$token->skip_ws($token)->is_terminator
       && ($expr = $$token->next_skip_ws($token)->as_expr($token, $scope, $prec))) {
        push(@exprs, $expr);
    }

    return $self->error("Missing 'end' at end of block, got: ", $token->text)
        unless $$token->is('end');
    
    $$token = $$token->next;

    return $self->[META]->[ELEMS]->construct(
        block => $self->[TEXT], $self->[POS], undef, \@exprs
    );

#    return undef;
#    if @exprs;
}



package Template::TT3::Element::Lbrace;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation',
    constants => ':elem_slots';


sub as_block {
    my ($self, $token, $scope, $prec) = @_;
    my (@exprs, $expr);

    # advance past terminator token
    $$token = $self->[NEXT];

    while (1) {
        if ($expr = $$token->as_expr($token, $scope, $prec)) {
            push(@exprs, $expr);
        }
        elsif ($$token->skip_ws($token)->is_terminator) {
            $$token = $$token->[NEXT];
        }
        else {
            last;
        }
    }

    return $self->error("Missing '}' at end of block, got: ", $$token->text)
        unless $$token->is('}');
    
    $$token = $$token->next;

    return $self->[META]->[ELEMS]->construct(
        block => $self->[TEXT], $self->[POS], undef, \@exprs
    );
}

package Template::TT3::Element::Rbrace;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation';


package Template::TT3::Element::End;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots';

sub as_expr {
#    ${$_[1]} = $_[0] if $_[1];
    return undef;
}

sub generate {
    $_[1]->generate_keyword(
        $_[0]->[TEXT]
    );
}
    

1;
