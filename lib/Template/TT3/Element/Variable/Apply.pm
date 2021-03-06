package Template::TT3::Element::Variable::Apply;

use Template::TT3::Class::Element
    debug     => 0,
    base      => 'Template::TT3::Element::Variable',
    view      => 'apply',
    constant  => {
        FINISH        => ')',
        SOURCE_FORMAT => '%s(%s)',
    };


sub parse_postfix {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    $self->advance($token);

    # TODO: should copy $lhs->[EXPR] and optimise away a whole layer
    $self->[EXPR] = $lhs;
    $self->[ARGS] = $$token->parse_block($token, $scope, 0, 1)
        || return $self->fail_missing( expressions => $token );

    $$token->is( $self->FINISH )
        || return $self->fail_missing( $self->FINISH, $token);

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
    $op->[RHS] = $self->[META]->[ELEMS]->create(
        sub => '<sub: ' . $self->[ARGS]->source . '>', 
            $self->[POS] + 1,       # POS   - skip past '(' 
            $self,                  # EXPR  - this element is sub name(args)
            $op->[RHS],             # BLOCK - body content
            $self->signature,       # ARGS  - summarised signature
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
    $_[SELF]->debug('calling variable: ', $_[SELF]->source) if DEBUG;
    
    # temporarily save ourselves in $TT_PARAMS_CALLER so that tt_params()
    # can report parameter errors from the perspective of the caller
    local $Template::TT3::Utils::TT_PARAMS_CALLER = $_[SELF];

#    print "*** DUMP ****\n", $_[CONTEXT]->dump_up, "\n";
    
#    $_[SELF]->debug("asking ARGS for params: $_[SELF]->[ARGS] => ", $_[SELF]->[ARGS]->source);
    
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


sub source {
    my $self = shift;
    sprintf(
        $self->SOURCE_FORMAT,
        $self->[EXPR]->source,
        $self->[ARGS]->source,
    );
}


sub OLD_text {
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





