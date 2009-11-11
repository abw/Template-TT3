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

package Template::TT3::Element::Separator;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element::Punctuation',
    constants => ':elem_slots',
    constant  => {
        is_delimiter => 1,
    },
    alias     => {
        skip_delimiter => 'next_skip_ws',
    };


#sub as_expr {
#    my ($self, $token, @args) = @_;
#    $$token = $self->[NEXT] if $token;
#    $self->[NEXT]->as_expr($token, @args);
#}


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
# Template::TT3::Element::Construct
#
# Base class for data constructs: () {} []
#-----------------------------------------------------------------------

package Template::TT3::Element::Construct;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation',
    constants => ':elem_slots';


sub sexpr {
    my $self = shift;
    $self->[EXPR]->sexpr(
        $self->SEXPR_FORMAT
    );
}

sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT, 
        $self->[EXPR]->source(@_)
    );
}


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # advance past opening token
    $self->accept($token);

    # parse expressions
    $self->[EXPR] = $$token->as_exprs($token, $scope)
        || return $self->missing( expressions => $token );

    # check next token matches our FINISH token
    return $self->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH );
    
    # advance past finish token
    $$token = $$token->next;

    # list/hash constructs can be followed by postops 
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


#-----------------------------------------------------------------------
# Constructs: [ ]  { }  ( )
#-----------------------------------------------------------------------

package Template::TT3::Element::List;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Construct',
    debug     => 0,
    constants => ':elem_slots :eval_args',
    constant  => {
        FINISH        => ']',
        SEXPR_FORMAT  => "<list:\n%s\n>",
        SOURCE_FORMAT => '[ %s ]',
    },
    alias     => {
        values => \&value,
    };


sub generate {
    $_[CONTEXT]->generate_list($_[SELF]);
}


sub value {
    $_[SELF]->debug("called value() on list: ", $_[SELF]->source) if DEBUG;
    return [
        $_[SELF]->[EXPR]->values($_[CONTEXT])
    ];
}

sub variable {
    $_[CONTEXT]->{ variables }
        ->use_var( $_[SELF] => $_[SELF]->value($_[CONTEXT]) );
}

sub text {
    $_[SELF]->debug("called text() on list: ", $_[SELF]->source) if DEBUG;
    return join(
        '',
        $_[SELF]->[EXPR]->text($_[CONTEXT])
    );
}



package Template::TT3::Element::Hash;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Construct',
    constant  => {
        FINISH        => '}',
        SEXPR_FORMAT  => "<hash:\n%s\n>",
        SOURCE_FORMAT => '{ %s }',
    };


sub as_block {
    my ($self, $token, $scope, $prec) = @_;
    my (@exprs, $expr);
 
    # advance past terminator token
    $self->accept($token);

    # parse expressions
    my $block = $$token->as_exprs($token)
        || return $self->missing( block => $token );
    
    # check next token matches our FINISH token
    return $self->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH );
    
    # advance past finish token
    $$token = $$token->next;

    # return $block, not $self
    return $block;
}



package Template::TT3::Element::Parens;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Construct',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<parens:\n  %s\n>",
        SOURCE_FORMAT => '( %s )',
    };

package Template::TT3::Element::Args;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Construct',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<args:\n  %s\n>",
        SOURCE_FORMAT => '( %s )',
    };




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

