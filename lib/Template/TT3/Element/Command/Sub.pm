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


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # Check precedence and advance past 'block' keyword
    $self->advance_expr($token, $scope, $prec, $force)
        || return;

    if ($self->[ARGS] = $$token->parse_signature($token, $scope, $self)) {
        # Got a parenthesised function signature, e.g. sub(...)
    }
    elsif ($self->[EXPR] = $$token->skip_ws($token)->parse_filename($token, $scope)) {
        # Got a name, see if it's got an arguments signature, e.g. sub foo(...)
        $self->[ARGS] = $$token->parse_signature($token, $scope, $self->[EXPR]);
    }
    
    # skip any whitespace then parse the following block
    $self->[BLOCK] = $$token->skip_ws($token)->parse_body($token, $scope, $self)
        || return $self->fail_missing( $self->ARG_BLOCK => $token );

    return $self;
}


sub text {
    my $code = $_[SELF]->value($_[CONTEXT]);
    return $code && $code->();
}


sub value {
    my ($self, $context) = @_;
    my $args  = $self->[ARGS];
    my $block = $self->[BLOCK];
    my $sub;

    if ($args) {
        my $sign  = $args->signature;
        $sub = sub {
            $context = $context->with(
                tt_params($self, $sign, undef, @_)
            );
            my @values = $block->values($context);
            return pop @values;
        };
    }
    else {
        $sub = sub {
            $context = $context->with;
            my @values = $block->values($context);
            return pop @values;
        };
    }
    
    if ($self->[EXPR]) {
        # subroutine has a name declared - we define the function and 
        # yield no value.  This is so that sub declaration statement like
        # sub foo() { .... } don't generate any output.
        my $name = $self->[EXPR]->value($context);
        $self->debug("installing function as $name") if DEBUG;
        $context->set_var(
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
