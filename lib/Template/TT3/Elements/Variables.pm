

#-----------------------------------------------------------------------
# Template:TT3::Element::Variable::Apply
#
# A wrapper around a variables and a list of arguments used to represent
# function application, e.g. foo(a,b), rather than just a function 
# reference, e.g. foo.  Not very efficient at the moment, but I'm not 
# worrying about optimisation ATM.
#-----------------------------------------------------------------------

package Template::TT3::Element::Variable::Apply;

use Template::TT3::Class 
    debug     => 0,
    base      => 'Template::TT3::Element::Variable',
    view      => 'apply',
    constants => ':elements',
    constant  => {
        FINISH        => ')',
        SEXPR_FORMAT  => "<apply:%s%s>",
        SEXPR_ARGS    => "<args:%s>",
        SOURCE_FORMAT => '%s(%s)',
    };


sub as_postfix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    $self->accept($token);

    # TODO: should copy $lhs->[EXPR] and optimise away a whole layer
    $self->[EXPR] = $lhs;
    $self->[ARGS] = $$token->as_exprs($token, $scope, 0, 1)
        || return $self->missing( expressions => $token );

    $$token->is( $self->FINISH )
        || return $self->missing( $self->FINISH, $token);

    $$token = $$token->next;
    
    $self->debug("EXPR: $self->[EXPR]   ARGS: $self->[ARGS]") if DEBUG;

    return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub variable {
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply( 
#       $_[SELF]->[ARGS]->values( $_[CONTEXT] )
        $_[SELF]->[ARGS]->params( $_[CONTEXT] )
    );

#    my @params = $_[SELF]->[ARGS]->params( $_[CONTEXT] );
#    $_[SELF]->debug("variable() params: ", $_[SELF]->dump_data(\@params)) if DEBUG or 1;
#    $_[SELF]->debug("ARGS: ", $_[SELF]->[ARGS]);
#    $_[SELF]->debug("PARAMS: ", $_[SELF]->[ARGS]->params( $_[CONTEXT] ));
}


sub variable_list {
    $_[SELF]->debug('variable_list() args are ', $_[SELF]->[ARGS]->source) if DEBUG;
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply_list( 
#       $_[SELF]->[ARGS]->values( $_[CONTEXT] )
        $_[SELF]->[ARGS]->params( $_[CONTEXT] )
    );
}


sub list_values {
    $_[SELF]->variable_list( $_[CONTEXT] )->values;
}


sub sexpr {
    my $self = shift;
    my $name = $self->[EXPR]->sexpr;
    my $args = $self->[ARGS]->sexpr( $self->SEXPR_ARGS );
    for ($name, $args) {
        s/^/  /gsm;
    }
    sprintf(
        $self->SEXPR_FORMAT,
        "\n" . $name,
        "\n" . $args . "\n"
    );
}


sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT,
        $self->[EXPR]->source,
        $self->[ARGS]->source,
    );
}



1;




