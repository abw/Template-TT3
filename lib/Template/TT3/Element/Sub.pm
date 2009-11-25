package Template::TT3::Element::Sub;

use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    utils     => 'tt_params',
    view      => 'sub',
    constants => ':elements';


sub value {
    my ($self, $context) = @_;

    my $block = $self->[BLOCK];
    my $sign  = $self->[ARGS];

    if (DEBUG) {
        $self->debug("activating lazy sub wrapper, signature is ", $self->dump_data($sign));
        $self->debug("block is $block");
        $self->debug("Creating sub for ", $block->source);
        $self->debug("Context is $context: \n", $context->dump_up);
    }
    
    return sub {
        $block->text(
            $context->with(
                tt_params($self, $sign, undef, @_)
            )
        );
    };
}

sub NOT_values {
    my ($self, $context) = @_;
    $self->debug("activating lazy sub wrapper");
    return "TODO";
}

sub source {
    $_[SELF]->debug_callers;
    $_[SELF]->[BLOCK]->source;
}


1;
