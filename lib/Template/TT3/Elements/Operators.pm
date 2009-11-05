#-----------------------------------------------------------------------
# base clas for all operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element',
    constants => ':elem_slots';



#-----------------------------------------------------------------------
# base class for unary operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Unary;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator',
    constants => ':elem_slots';

sub as_expr_prefix {
    my ($self, $token, $scope, $prec) = @_;

    # operator precedence
    return undef 
        if $prec && $self->[META]->[RPREC] < $prec;

    # advance token past operator
    $$token = $self->[NEXT];
    
    #$self->debug("prefix op $self->[TEXT] parsing expr with prec: ", $self->[META]->[RPREC]) if DEBUG;
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter
    $self->[RHS] = $$token->as_expr($token, $scope, $self->[META]->[RPREC])
        || return $self->error("Missing expression after operator: $self->[TEXT]");

#    $self->debug("RHS: $self->[RHS]\n");
    
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub as_postop_postfix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return undef 
        if $prec && $self->[META]->[LPREC] <= $prec;

    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}



#-----------------------------------------------------------------------
# base class for unary prefix operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Unary::Prefix;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary',
    constants => ':elem_slots',
    alias     => {
        as_expr => 'as_expr_prefix',
    };


sub generate {
    $_[1]->generate_prefix(
        $_[0]->[TEXT],
        $_[0]->[RHS],
    );
}



#-----------------------------------------------------------------------
# base class for unary postfix operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Unary::Postfix;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary',
    constants => ':elem_slots',
    alias     => {
        as_postop => 'as_postop_postfix',
    };

sub generate {
    $_[1]->generate_postfix(
        $_[0]->[TEXT],
        $_[0]->[LHS],
    );
}



#-----------------------------------------------------------------------
# base class for unary operators that are either prefix or postfix
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Unary::PrePostfix;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary',
    constants => ':elem_slots',
    alias     => {
        as_expr   => 'as_expr_prefix',
        as_postop => 'as_postop_postfix',
    };



sub generate {
#    $_[0]->debug("\nOP $_[0]->[TEXT]   lhs [$_[0]->[LHS]]  rhs [$_[0]->[RHS]]");
    $_[0]->[RHS]
        ? $_[1]->generate_prefix(
            $_[0]->[TEXT],
            $_[0]->[RHS],
          )
        : $_[1]->generate_postfix(
            $_[0]->[TEXT],
            $_[0]->[LHS],
          );
}


#-----------------------------------------------------------------------
# unary operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Not;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary::Prefix';

package Template::TT3::Element::NotLo;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Not';


package Template::TT3::Element::Inc;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary::PrePostfix';

package Template::TT3::Element::Dec;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Unary::PrePostfix';



#-----------------------------------------------------------------------
# base class for binary operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Binary;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator',
    import    => 'class',
    constants => ':elem_slots';

sub generate {
    $_[1]->generate_binop(
        $_[0]->[TEXT],
        $_[0]->[LHS],
        $_[0]->[RHS],
    );
}

sub as_expr {
    my ($self, $token, $scope) = @_;
    return undef;
}

sub as_postop_left {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # Operator precedence - if our leftward binding precedence is less than
    # or equal to the precedence requested then we return the LHS.  
    # The 'or equal' part gives us left asociativity so that "a + b + c"
    # is parsed as "(a + b) + c"
    return $lhs 
        if $prec && $self->[META]->[LPREC] <= $prec;

    # otherwise this operator has a higher precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher precedence can bind tighter
    $self->[RHS] = $$token->as_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->error("Missing expression after operator: $self->[TEXT]");
    
    # at this point the next token might be a lower precedence operator, so
    # we give it a chance to continue with the current operator as the LHS
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub as_postop_right {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # This is identical to as_postop_left() in all but one regard.  If
    # we have an equal precedence between two consecutive operators then 
    # we bind the RHS pair tighter than the LHS pair.  To do this we remove
    # the 'or equal' part described in as_postop_left() so that "a = b = c"
    # is parsed as "a = (b = c)"
    return $lhs 
        if $prec && $self->[META]->[LPREC] < $prec;

    # otherwise this operator has a >= precedence so should parse the RHS
    $self->[LHS] = $lhs;
    
    # advance token past operator
    $$token = $self->[NEXT];
    
    # parse the RHS as an expression, passing our own precedence so that 
    # any operators with a higher or equal precedence can bind tighter
    $self->[RHS] = $$token->as_expr($token, $scope, $self->[META]->[LPREC])
        || return $self->error("Missing expression after operator: $self->[TEXT]");
    
    # at this point the next token might be a lower or equal precedence 
    # operator, so we give it a chance to continue with the current operator
    # as the LHS
    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


#-----------------------------------------------------------------------
# base class for binary operators with left associativity
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Binary::Left;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary',
    alias     => {
        as_postop => 'as_postop_left',
    };


#-----------------------------------------------------------------------
# base class for binary operators with right associativity
#-----------------------------------------------------------------------

package Template::TT3::Element::Operator::Binary::Right;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary',
    alias     => {
        as_postop => 'as_postop_right',
    };



#-----------------------------------------------------------------------
# various binary operators
#-----------------------------------------------------------------------

package Template::TT3::Element::Dot;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Left',
    constants => ':elem_slots';


package Template::TT3::Element::Plus;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Left',
    constants => ':elem_slots';


package Template::TT3::Element::Star;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Left',
    constants => ':elem_slots';


package Template::TT3::Element::NumLt;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Left',
    constants => ':elem_slots';


package Template::TT3::Element::Assign;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Right',
    constants => ':elem_slots';

package Template::TT3::Element::Arrow;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Right',
    constants => ':elem_slots';

sub generate {
    $_[0]->debug("arrows [$_[0]->[TEXT]] [$_[0]->[LHS]] [$_[0]->[RHS]]");
    $_[1]->generate_binop(
        ' "' . $_[0]->[TEXT] . '" ',    # for debugging
        $_[0]->[LHS],
        $_[0]->[RHS],
    );
}


package Template::TT3::Element::IfThen;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Left',
    constants => ':elem_slots';

sub TMP_generate {
    $_[1]->generate_if_then(
        $_[0]->[TEXT],
        $_[0]->[LHS],
        $_[0]->[RHS],
    );
}


package Template::TT3::Element::IfElse;

use Template::TT3::Class 
    version   => 3.00,
    base      => 'Template::TT3::Element::Operator::Binary::Left',
    constants => ':elem_slots';


1;

