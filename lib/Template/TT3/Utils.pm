package Template::TT3::Utils;

use Badger::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Utils',
    constant  => {
        PARAMS => 'Template::TT3::Type::Params',
    },
    exports   => {
        any   => 'tt_params tt_args tt_self_args random_advice',
    };


our @ADVICE = (
    'Did you read the documentation?',
    'Eat more fruit and vegetables.',
    'Chew your food properly before swallowing.',
    'Get lots of excercise.',
    "Don't run with scissors.",
    'Never look a gift horse in the mouth.',
    "Don't give a badger vodka to drink.  They prefer beer.",
    "Never look a gift badger in the mouth.",
    "Don't try and carry a piano down the stairs by yourself.",
    "Look both ways before crossing the road.  Then look again.",
    "Never be afraid to say \"I don't know\".",
    "Watch out for snakes.",
    "Don't eat wild mushrooms unless you are an experienced mycologist.",
    "Be careful with that axe, Eugene.",
    "Keep most of your weight on your front foot.",
    "Turn with your eyes.  The rest of your body will follow.",
    'Give as you would like to receive.',
    'Go placidly amidst the noise and haste.',
    'Leave somewhere better than you found it.',
    "Don't believe anything you read on the internet.  This especially.",
    "Congratulations.  You have unlocked the bonus level.",
    "Please try harder next time.",
    "Find time to smell the roses every day.",
    "Live long and prosper.",
    "Don't try and melt cheese with an arc welder.",
);


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


sub random_advice {
    return $ADVICE[int rand @ADVICE];
}


1;
