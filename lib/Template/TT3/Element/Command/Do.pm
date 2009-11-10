package Template::TT3::Element::Command::Do;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elem_slots :eval_args',
    alias      => {
        value  => \&text,
        values => \&text,
    };

sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # operator precedence
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token reference
    $self->accept($token);

    # skip past keyword and parse block following
    $self->[EXPR] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );
        
    return $self;
}


sub text {
    # hmmm... we need a way to only return value from last expr
    $_[SELF]->[EXPR]->text($_[CONTEXT]);
}


1;
