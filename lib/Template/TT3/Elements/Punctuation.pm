package Template::TT3::Element::Punctuation;

use Template::TT3::Elements::Literal;
use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Literal',
    constants => ':elem_slots';

sub as_expr {
    return undef;
}

sub generate {
    $_[1]->generate_punctuation(
        $_[0]->[TOKEN]
    );
}


#-----------------------------------------------------------------------
# TODO: separator
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# statement delimiter: ';' or '%]' or some other tag end
#-----------------------------------------------------------------------

package Template::TT3::Element::Delimiter;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Punctuation',
    constants => ':elem_slots',
    constant  => {
        is_delimiter => 1,
    };
#    alias     => {
#        skip_delimiter => 'next_skip_ws',
#    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    $_[0]->next_skip_ws($_[1])->skip_delimiter($_[1]);
}



sub as_block {
    my ($self, $token, $scope, $prec) = @_;

#    $self->debug("asking delimiter for as_block(), next token is ", $$token->token);
#    $self->debug("TOKEN: $token   =>   $$token");
 
    my $block = $$token->as_exprs($token, $scope, $prec)
        || return $self->error("Missing block after 'do'");

    # TODO: replace these with as_terminator()
    return $self->error("Missing 'end' at end of block, got: ", $token->text)
        unless $$token->is('end');
    $$token = $$token->next;

    return $block;
}



#-----------------------------------------------------------------------
# TODO: terminator
#-----------------------------------------------------------------------

package Template::TT3::Element::Terminator;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation',
    constants => ':elem_slots',
    constant  => {
        is_terminator => 1,
    },
    alias     => {
        as_expr    => 'null',
        as_block   => 'null',
        as_postop  => 'reject',
        terminator => 'next_skip_ws',
    };

#sub as_expr {
#    shift->next_skip_ws($_[0])->as_expr(@_);
#}

# TODO: as_terminator() to terminate and return preceeding block  


#-----------------------------------------------------------------------
# {
#-----------------------------------------------------------------------

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

    my $block = $$token->as_exprs($token)
        || return $self->error("Missing block after $self->[TOKEN]");
    
    # TODO: replace with as_terminator()
    return $self->error("Missing '}' at end of block, got: ", $$token->text)
        unless $$token->is('}');
    
    $$token = $$token->next;

    return $block;
}



#-----------------------------------------------------------------------
# end
#-----------------------------------------------------------------------

package Template::TT3::Element::End;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Terminator',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_keyword(
        $_[0]->[TOKEN]
    );
}




1;    

