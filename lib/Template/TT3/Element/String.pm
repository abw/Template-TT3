package Template::TT3::Element::String;

use Template::TT3::Class::Element
    version   => 2.69,
    base      => 'Template::TT3::Element::Text',
    view      => 'string',
    constant  => {
        SOURCE_FORMAT => '%s',
    },
    alias     => {
        value          => \&text,
        values         => \&text,
        parse_filename => \&parse_expr,
    };


sub parse_expr {
    my ($self, $token, $scope, $prec) = @_;
    
    # copy original TEXT into EXPR in case we don't already have a 
    # reduced form (i.e. without quotes)
    $self->[EXPR] = $self->[TOKEN]
        unless defined $self->[EXPR];
    
    # strings can be followed by postops (postfix and infix operators)
    return $$token->next_skip_ws($token)
        ->parse_infix($self, $token, $scope, $prec);
}


sub text {
    $_[SELF]->[EXPR];
}


sub filename {
    $_[SELF]->text( $_[CONTEXT] );
}


sub template {
    my $self = shift;
    return $self->fetch_template(
        $self->text(@_), @_
    );
}


sub variable {
    $_[CONTEXT]->use_var( 
        $_[SELF], 
        $_[SELF]->text( $_[CONTEXT] )
    );
}


1;
