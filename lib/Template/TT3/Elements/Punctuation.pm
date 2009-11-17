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
    as        => 'block',
    constants => ':elem_slots',
    constant  => {
        is_delimiter => 1,
        FINISH       => 'end',
    };
#    alias     => {
#        skip_delimiter => 'next_skip_ws',
#    };


sub skip_delimiter {
    # we can always skip whitespace to skip over a delimiter
    $_[0]->next_skip_ws($_[1])->skip_delimiter($_[1]);
}


sub OLD_as_block {
    my ($self, $token, $scope, $prec) = @_;

#    $self->debug("asking delimiter for as_block(), next token is ", $$token->token);
#    $self->debug("TOKEN: $token   =>   $$token");
 
    my $block = $$token->as_exprs($token, $scope, $prec)
        || return $self->missing( expressions => $token );

    $self->debug("DELIMITER: ", $$token->token);
    
    # TODO: replace these with as_terminator()
    return $self->missing( end => $token )
        unless $$token->is('end');

    $self->debug("GOT END: ", $$token->source);
        
    $$token = $$token->next;

    $self->debug("NEXT TOKEN: ", $$token->token);

    return $block;
}


#-----------------------------------------------------------------------
# Template::TT3::Element::TagEnd - tag end token
#-----------------------------------------------------------------------

package Template::TT3::Element::TagEnd;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Delimiter',
    constants => ':eval_args';
    
sub view {
    $_[CONTEXT]->view_tag_end($_[SELF]);
}


#-----------------------------------------------------------------------
# TODO: terminator
#-----------------------------------------------------------------------

package Template::TT3::Element::Terminator;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Punctuation',
    view      => 'terminator',
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
    constants => ':elem_slots :eval_args';


sub sexpr {
    my $self = shift;
    $self->[EXPR]->sexpr(
        shift || $self->SEXPR_FORMAT
    );
}

sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT, 
        $self->[EXPR]->source(@_)
    );
}

sub variable {
    $_[CONTEXT]->{ variables }
        ->use_var( $_[SELF] => $_[SELF]->value($_[CONTEXT]) );
}

sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # advance past opening token
    $self->accept($token);

    # parse expressions.  Any precedence (0), allow empty lists (1)
    $self->[EXPR] = $$token->as_exprs($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );
    
#    $self->debug("list parsed expr: $self->[EXPR]");

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
        SEXPR_FORMAT  => "<list:%s>",
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


sub text {
#    $_[SELF]->debug_caller;
#    $_[SELF]->debug("called text() on list: ", $_[SELF]->source) if DEBUG;
    return join(
        '',
        $_[SELF]->[EXPR]->text($_[CONTEXT])
    );
}



package Template::TT3::Element::Hash;

use Template::TT3::Class 
    debug     => 0,
    base      => 'Template::TT3::Element::Construct',
    as        => 'block',
    constants => ':elem_slots :eval_args',
    constant  => {
        FINISH        => '}',
        SEXPR_FORMAT  => "<hash:%s>",
        SOURCE_FORMAT => '{ %s }',
    };


sub value {
    $_[SELF]->debug("called value() on hash: ", $_[SELF]->source) if DEBUG;
    return {
        $_[SELF]->[EXPR]->pairs($_[CONTEXT])
    };
}


package Template::TT3::Element::Parens;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Construct',
    constants => ':eval_args :elem_slots',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<parens:%s>",
        SOURCE_FORMAT => '( %s )',
    };

sub as_postfix {
    shift->become('var_apply')->as_postfix(@_);
}


sub as_args {
    my ($self, $token, $scope, $prec, $force) = @_;

    # advance past opening token
    $self->accept($token);

    # parse expressions, any precedence (0), allow empty blocks (1)
    $self->[EXPR] = $$token->as_exprs($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );

    # check next token matches our FINISH token
    return $self->missing( $self->FINISH, $token)
        unless $$token->is( $self->FINISH );
    
    # advance past finish token
    $$token = $$token->next;

    return $self;
}

sub value {
    my @values = $_[SELF]->[EXPR]->values($_[CONTEXT]);
    return @values > 1
        ? join('', @values)
        : $values[0];
}

sub values {
    return $_[SELF]->[EXPR]->values($_[CONTEXT]);
}

sub text {
    $_[SELF]->[EXPR]->text($_[CONTEXT])
}


package Template::TT3::Element::Args;

use Template::TT3::Class 
    base      => 'Template::TT3::Element::Construct',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<args:%s>",
        SOURCE_FORMAT => '( %s )',
    };




#-----------------------------------------------------------------------
# end
#-----------------------------------------------------------------------

package Template::TT3::Element::End;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Terminator',
    view      => 'keyword',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_keyword(
        $_[0]->[TOKEN]
    );
}




1;    

