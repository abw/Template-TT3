package Template::TT3::Utils;

use Badger::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Utils',
    constants => 'HASH',
    constant  => {
#        PARAMS => 'Template::TT3::Type::Params',   # causes too many problems
        PARAMS => 'HASH',
    },
    exports   => {
        any   => 'tt_params tt_args tt_self_args random_advice hashlike',
    };


our $TT_PARAMS_CALLER;
our $TT_PARAMS_BLESS = PARAMS unless PARAMS eq HASH;

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


sub hashlike($) {
    ref $_[0] && ref $_[0] eq HASH || ref $_[0] eq PARAMS;
}
 
sub tt_args {
    my $opts = pop @_ if @_ && ref $_[-1] eq PARAMS;
#    print "TT_ARGS: (", join(', ', @_), ")\n";
#    print PARAMS, " check: got opts: $opts\n"; # if $opts;
    return ($opts, @_);
}


sub tt_self_args {
    my $self = shift;
    my $opts = pop @_ if @_ && ref $_[-1] eq PARAMS;
    return ($self, $opts, @_);
}


sub tt_params {
    my ($self, $sig, $vars, @args) = @_;
    my $opts = @_ && ref $args[-1] eq PARAMS ? pop @args : { };
    my $from = $TT_PARAMS_CALLER || $self;      # hack to allow remote poking
    $vars ||= { };
    my ($name, $value);

    if (DEBUG) {
        $self->debug("sig: ", $self->dump_data($sig));
        $self->debug("vars: ", $self->dump_data($vars));
        $self->debug("args: ", $self->dump_data(\@args));
        $self->debug("self is $self: ", $self->source);
    }

    # look for each scalar positional argument
    foreach $name (@{ $sig->{'$'} }) {
        $self->debug("looking for $name in args...") if DEBUG;

        $value = exists $opts->{ $name }
            ? delete $opts->{ $name }
            : @args 
                ? shift @args 
                : $from->fail_args_missing( $self->source, $name );
        $vars->{ $name } = defined $value
            ? $value : warn "Undefined value for $name argument\n";
    }
    
    # store remaining positional arguments
    if ($name = $sig->{'@'}) {
        $vars->{ $name } = \@args;
    }
    elsif (@args) {
        $from->fail_args_posit( $self->source, join(', ', @args) );
    }

    # store remaining named params
    if ($name = $sig->{'%'}) {
        $vars->{ $name } = $opts;
    }
    elsif (%$opts) {
        $from->fail_args_named( $self->source, join(', ', keys %$opts) );
    }
    
    return $vars;
}


sub random_advice {
    return $ADVICE[int rand @ADVICE];
}


1;
