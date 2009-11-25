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


sub parse_postfix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    $self->advance($token);

    # TODO: should copy $lhs->[EXPR] and optimise away a whole layer
    $self->[EXPR] = $lhs;
    $self->[ARGS] = $$token->parse_block($token, $scope, 0, 1)
        || return $self->missing_error( expressions => $token );

    $$token->is( $self->FINISH )
        || return $self->missing_error( $self->FINISH, $token);

    $$token = $$token->next;
    
    $self->debug("EXPR: $self->[EXPR]   ARGS: $self->[ARGS]") if DEBUG;

    return $$token->skip_ws->parse_infix($self, $token, $scope, $prec);
}


sub as_lvalue  {
    my ($self, $op, $scope) = @_;
#    my $signature = $self->signature;

    # rewrite operator so LHS contains our variable expression (effectively
    # without the args) and RHS contains a lazy subroutine with a signature
    # extracted from out args
    $op->[LHS] = $self->[EXPR];
    $op->[RHS] = $self->[META]->[ELEMS]->construct(
        sub => '<sub: ' . $self->[ARGS]->source . '>', 
            $self->[POS], 
            undef,                  # EXPR
            $op->[RHS],             # BLOCK
            $self->signature,       # ARGS
    );
    
    $self->debug("created new sub wrapper for $op rhs: ", $op->[RHS]) if DEBUG;
    
    return $op;
}


sub signature {
    $_[0]->[BLOCK] ||= do {
        my ($self, $name) = @_;
        my $args = $self->[ARGS];
        my $sign = { };
        my $arg;

        foreach $arg ($args->exprs) {
            $arg->in_signature($name, $sign);
        }
        $sign;
    };
}


sub variable {
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply( 
        $_[SELF]->[ARGS]->params( $_[CONTEXT] )
    );

#    $DB::single=1;
#    $_[SELF]->debug("fetching variable for apply from expr: $_[SELF]->[EXPR]") if DEBUG or 1;
#    my $var = $_[SELF]->[EXPR]->variable( $_[CONTEXT] );
#    $_[SELF]->debug("fetched variable for apply: $var") if DEBUG or 1;
#    $_[SELF]->debug("args are $_[SELF]->[ARGS]") if DEBUG or 1;
#    my @params = $_[SELF]->[ARGS]->params( $_[CONTEXT] );
#    $_[SELF]->debug("var is $var   params are ", $_[SELF]->dump_data(\@params)) if DEBUG or 1;
#    my $result = $var->apply(@params);
#    $_[SELF]->debug("result is $result") if DEBUG or 1;
#    return $result;
}


sub variable_list {
    $_[SELF]->debug('variable_list() args are ', $_[SELF]->[ARGS]->source) if DEBUG;
    $_[SELF]->[EXPR]->variable( $_[CONTEXT] )->apply_list( 
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

sub TMP_text {
    my $self = shift;
    $self->debug("TEXT");
    return 'Apply->text()';
}


1;

__END__

=head1 NAME

Template:TT3::Element::Variable::Apply - element representing function application "()"

=head1 DESCRIPTION

This implements an element that is a wrapper around a variables and a list of
arguments used to represent function application, e.g. foo(a,b), rather than
just a function reference, e.g. foo. It's not particularly efficient at the
moment, but I'm not worrying about optimisation ATM.





