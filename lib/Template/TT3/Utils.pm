package Template::TT3::Utils;

use Badger::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Utils',
    constant  => {
        PARAMS => 'Template::TT3::Type::Params',
    },
    exports   => {
        any   => 'tt_params tt_args tt_self_args',
    };


sub tt_args {
    my $opts = pop @_ if @_ && ref $_[-1] eq PARAMS;
    return ($opts, @_);
}


sub tt_self_args {
    my $self = shift;
    my $opts = pop @_ if @_ && ref $_[-1] eq PARAMS;
    return ($self, $opts, @_);
}


sub tt_params {
    my ($self, $sig, $vars, @args) = @_;
    my $opts = @args && ref $args[-1] eq PARAMS ? pop @args : { };
    $vars ||= { };
    my ($name, $value);

    # look for each scalar positional argument
    foreach $name (@{ $sig->{'$'} }) {
        $self->debug("looking for $name in args...\n") if DEBUG;
        $value = exists $opts->{ $name }
            ? delete $opts->{ $name }
            : @args 
                ? shift @args 
                : $self->error("Missing argument for $name\n"); # TODO: warn/throw
        $vars->{ $name } = defined $value
            ? $value : warn "Undefined value for $name argument\n";
    }
    
    # store remaining positional arguments
    if ($name = $sig->{'@'}) {
        $vars->{ $name } = \@args;
    }
    elsif (@args) {
        $self->error_msg( bad_args => $self->source, join(', ', @args) );
    }

    # store remaining named params
    if ($name = $sig->{'%'}) {
        $vars->{ $name } = $opts;
    }
    elsif (%$opts) {
        $self->error_msg( bad_params => $self->source, join(', ', keys %$opts) );
    }
    
    return $vars;
}


1;
