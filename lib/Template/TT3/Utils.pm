package Template::TT3::Utils;

use Badger::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Utils',
    constant  => {
        PARAMS => 'Template::TT3::Type::Params',
    },
    exports   => {
        any   => 'tt_params',
    };


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
    $vars->{ $name } = \@args 
        if $name = $sig->{'@'};

    # store remaining named params
    $vars->{ $name } = $opts 
        if $name = $sig->{'%'};

    return $vars;
}


1;
