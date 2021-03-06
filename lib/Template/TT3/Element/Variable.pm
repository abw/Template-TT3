package Template::TT3::Element::Variable;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'variable',
    roles     => 'pair',
    alias => {
        source        => 'token',
        values        => \&value,       # default to scalar context
        variable_list => \&variable,    # subclasses may redefine
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;

    # advance token
    $$token = $self->[NEXT];
    
    # TODO ask scope to lookup variable from the symbol table

    return $$token->parse_postfix($self, $token, $scope, $prec);
}


sub as_lvalue {
    # my ($self, $op, $rhs, $scope) = @_;
    # nothing special here, but other elements may modify/wrap either
    # the LHS or RHS before stuffing them into $op
    # TODO: this whole concept needs reworking
    return $_[1];
}


# We treat 'foo' as short-hand for 'foo=foo' when used in pair context

sub as_pair {
    my $self = shift;
    my $elems = $self->[META]->[ELEMS];
    my $name  = $elems->create(
        word => $self->[TOKEN], $self->[POS]
    );
    $self->debug("Creating pair from variable") if DEBUG;
    return $elems->create(
        op_pair => "[=>]", $self->[POS], $name, $self
    );
}


sub text {
    $_[SELF]->debug("variable text(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->text($_[SELF]);
}


sub value {
    $_[SELF]->debug("variable value(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->value($_[SELF]);
}


sub maybe {
    $_[SELF]->debug("variable maybe(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable( $_[CONTEXT] )->maybe($_[SELF]);
}


sub list_values {
    $_[SELF]->debug("variable values(): ", $_[SELF]->source) if DEBUG;
    # explicitly force list context
    $_[SELF]->variable( $_[CONTEXT] )->values($_[SELF]);
}


sub pairs {
    $_[SELF]->debug("variable pairs(): ", $_[SELF]->source) if DEBUG;

    $_[SELF]->debug(
        "variable '", $_[SELF]->source, "' is ", 
        $_[SELF]->variable( $_[CONTEXT] )
    ) if DEBUG;

    # explicitly force list context
    my @values = $_[SELF]->variable( $_[CONTEXT] )->pairs($_[SELF]);

    # check we got an even number of items
    return @values % 2
        ? $_[SELF]->fail_pairs_odd( scalar(@values) )
        : @values;
}


sub name {
    $_[SELF]->debug("variable name(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->[TOKEN];
}


sub variable {
    $_[CONTEXT]->var( $_[SELF]->[TOKEN] );
}


sub assign {
    $_[SELF]->debug("variable assign(): ", $_[SELF]->source) if DEBUG;
    $_[SELF]->variable($_[CONTEXT])->set($_[2], $_[SELF]);
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
    return $self->signature_error( bad_arg => $name )
        if $self->[ARGS] || $self->[EXPR];

    # fail if there's an existing argument with same name
    my $token = $self->[TOKEN];
    return $self->signature_error( dup_arg => $name, $token )
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





# TODO: source() should add args

1;

__END__


#-----------------------------------------------------------------------
# Template::TT3::Element::Variable
#
# Element representing a variable name in a parse tree.
#-----------------------------------------------------------------------

