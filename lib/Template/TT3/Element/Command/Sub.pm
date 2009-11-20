package Template::TT3::Element::Command::Sub;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command::Block',
    utils      => 'tt_params',
    constants  => ':elements BLANK',
    alias      => {
        values => \&value,
    };


sub text {
    my $code = $_[SELF]->value($_[CONTEXT]);
    return $code && $code->();
}


sub value {
    my ($self, $context) = @_;
    my $args  = $self->[ARGS];
    my $block = $self->[BLOCK];
    my $vars  = $context->{ variables };

    my $sub = $args
        ? sub {
            local $vars->{ variables };
            $vars->set_vars(
                tt_params($self, $args, undef, @_)
            );
            my @values = $block->values($context);
            return pop @values;
        }
        : sub {
            local $vars->{ variables };
            my @values = $block->values($context);
            return pop @values;
        };
    
    if ($self->[EXPR]) {
        # subroutine has a name declared - we define the function and 
        # yield no value.  This is so that sub declaration statement like
        # sub foo() { .... } don't generate any output.
        my $name = $self->[EXPR]->value($context);
        $self->debug("installing function as $name") if DEBUG;
        $context->{ variables }->set_var(
            $name,
            $sub
        );
        return ();
    }

    return $sub;
}


sub source {
    my $self = shift;
    my $name = $self->[EXPR] 
        ? $self->[EXPR]->source
        : $self->[TOKEN];
# TODO: make signature a proper element so we can view its source
#    my $args = $self->[ARGS]
#        ? $self->[ARGS]->source
#        : ();
    my $args = '()';
    return "$name$args";
}

1;
