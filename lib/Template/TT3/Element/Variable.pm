package Template::TT3::Element::Variable;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'variable',
    constants => ':elements',
    constant  => {
        SEXPR_FORMAT => '<variable:%s>', 
    },
    alias => {
        source        => 'token',
        values        => \&value,       # default to scalar context
        variable_list => \&variable,    # subclasses may redefine
    };


sub as_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance token
    $$token = $self->[NEXT];
    
    # TODO ask scope to lookup variable from the symbol table

    return $$token->as_postfix($self, $token, $scope, $prec);
    
    #$self->[ARGS] = $$token->as_args($token, $scope);
    
    # TODO: allow () [] {} following variable word
    #return $$token->as_postfix($self, $token, $scope, $prec);
    
    # variables can be followed by postops (postfix and infix operators)
    #return $$token->skip_ws->as_postop($self, $token, $scope, $prec);
}


sub as_lvalue {
    return $_[0];
}


sub text {
    $_[SELF]->debug("variable text(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->text;
}


sub value {
    $_[SELF]->debug("variable value(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->value;
}


sub list_values {
    $_[SELF]->debug("variable values(): ", $_[SELF]->source) if DEBUG;
    # explicitly force list context
    $_[SELF]->variable( $_[CONTEXT] )->values;
}


sub pairs {
    $_[SELF]->debug("variable pairs(): ", $_[SELF]->source) if DEBUG;

    # explicitly force list context
    my @values = $_[SELF]->variable( $_[CONTEXT] )->values;

    # check we got an even number of items
    return @values % 2
        ? $_[SELF]->error_msg( odd_pairs => scalar(@values) => $_[SELF]->source )
        : @values;
}


sub name {
    $_[SELF]->debug("variable name(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->[TOKEN];
}


sub variable {
    $_[SELF]->debug("variable variable(): ", $_[SELF]->source) if DEBUG;
    $_[CONTEXT]->{ variables }
         ->var( $_[SELF]->[TOKEN] );
}


sub assign {
    $_[SELF]->debug("variable assign(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable($_[CONTEXT])->set($_[2]);
#    return ();
}


# Signature for a function, e.g. foo(a, b, @c, %d) is:
# {  a => '$', b => '$', c => '@', d => '%',       # name => type
#    '$' => ['a', 'b'],     # list of scalar positional args
#    '@' => 'c',            # positional args collector
#    '%' => 'd' ,           # named parameters collector
# }
# Each argument in an argument list fills its own entry into the
# shared hash array, or barfs if there's a conflict with an existing
# argument.

sub in_signature {
    my ($self, $name, $signature) = @_;
    my $sigil = '$';
    $signature ||= { };

    $self->debug("variable signature(): ", $self->source) if DEBUG;

    # we can't be an argument in a function signature if we have args
    # or we have a dynamic name, e.g. $$foo
    return $self->bad_signature( bad_arg => $name )
        if $self->[ARGS] || $self->[EXPR];

    # fail if there's an existing argument with same name
    my $token = $self->[TOKEN];
    return $self->bad_signature( dup_arg => $name, $token )
        if $signature->{ $token };

    # save (name => type) pair
    $signature->{ $token } = $sigil;

    # add name to '$' scalar argument list
    my $args = $signature->{ $sigil } ||= [ ];
    push(@$args, $token);

    return $signature;
}


sub generate {
    $_[CONTEXT]->generate_variable(
        $_[SELF]->[TOKEN],
    );
}


sub sexpr {
    return sprintf(
        $_[SELF]->SEXPR_FORMAT,
        $_[SELF]->[TOKEN],
    );

    # TODO: won't need args once we have a 'var_apply' element
    my $args = $_[SELF]->[ARGS];
    my $format;
    
    if ($args) {
        $args = $args->sexpr;
        $args =~ s/^/  /gsm;
        $format = $_[SELF]->SEXPR_ARGS;
    }
    else {
        $args = '';
        $format = $_[SELF]->SEXPR_FORMAT;
    }
    sprintf(
        $format,
        $_[SELF]->[TOKEN],
        $args
    );
}




# TODO: source() should add args

1;

__END__


#-----------------------------------------------------------------------
# Template::TT3::Element::Variable
#
# Element representing a variable name in a parse tree.
#-----------------------------------------------------------------------

