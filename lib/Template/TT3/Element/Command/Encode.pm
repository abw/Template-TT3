package Template::TT3::Element::Command::Encode;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Command::Block',
    constants  => ':elem_slots :eval_args',
    constant   => {
        ARG_NAME => 'encoder',      # changed in ...::Decode subclass
    },
    alias      => {
        value  => \&text,
        values => \&value,
    },
    messages => {
        bad_codec => 'Invalid %s specified for %s command: %s',
    };

use Badger::Codecs 'Codec';


sub as_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Operator precedence.
    return undef
        if $prec && ! $force && $self->[META]->[LPREC] <= $prec;

    # advance token past keyword
#    $self->accept($token);

    # parse code name as a filename, so we can accept foo.bar, Foo::Bar, etc.
    $self->[LHS] = $$token->next_skip_ws($token)->as_filename($token, $scope)
        || return $self->missing( $self->ARG_NAME => $token );

    # parse block following the expression
    $self->[RHS] = $$token->as_block($token, $scope)
        || return $self->missing( block => $token );

    return $self;
}


sub as_postop {
    my ($self, $lhs, $token, $scope, $prec) = @_;

    # operator precedence
    return $lhs
        if $prec && $self->[META]->[LPREC] <= $prec;

    # store RHS and advance token past keyword 
    $self->[RHS] = $lhs;
    $self->accept($token);

    # parse codec name 
    $self->[LHS] = $$token->as_filename($token, $scope)
        || return $self->missing( $self->ARG_NAME => $token );
    
    return $self;
}

sub codec {
    # may want to eval this, or have a TT3 subclass of Badger::Codecs, mainly
    # so we can generate nice error messages saying "Invalid encoder specified
    # in 'encode' command"
    return eval { 
        Codec( $_[SELF]->[LHS]->filename( $_[CONTEXT] ) ) 
    }
    || $_[SELF]->error_msg( 
        bad_codec => $_[SELF]->ARG_NAME, $_[SELF]->[TOKEN], $@->info
    );
}
    
sub text {
    $_[SELF]->codec( $_[CONTEXT] )->encode( 
        $_[SELF]->[RHS]->text( $_[CONTEXT] )
    );
}


1;
