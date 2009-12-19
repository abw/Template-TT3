package Template::TT3::Iterator;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Base',
    constants => 'HASH ARRAY',
    utils     => 'blessed',
    constant  => {
        SELF  => 0,
        DATA  => 0,
        SIZE  => 1,
        INDEX => 2,
    };
#    accessors => 'size max index count first last',

*number = \&count;

our $AUTOLOAD;
our @ICFL      = qw( index count first last );
our @SMICFL    = qw( size max index count first last );
our @PREV_NEXT = qw( prev next ); 
our @MAX_INDEX = qw( max index );


sub new {
    my $class = shift;
    my $data  = shift || [ ];

    if (ref $data eq HASH) {
        # map a hash into a list of { key => ???, value => ??? } hashes,
        # one for each key, sorted by keys
        $data = [ 
            map { { key => $_, value => $data->{ $_ } } }
            sort keys %$data 
        ];
    }
    elsif (blessed $data && $data->can('as_list')) {
        # TODO: tt_loop() / tt_list() / tt_items() ??
        $data = $data->as_list;
    }
    elsif (ref $data ne ARRAY) {
        # coerce any non-list data into an array reference
        $data  = [ $data ];
    }
    
    bless [$data, scalar @$data, -1], $class;
}


sub reset {
    $_[SELF]->[INDEX] = -1;
}


sub done {
    $_[SELF]->[INDEX] >= $_[SELF]->[SIZE] - 1;
}


sub index {
    $_[SELF]->[INDEX];
}


sub count {
    $_[SELF]->[INDEX] + 1;
}


sub first {
    $_[SELF]->[INDEX] == 0;
}


sub last {
    $_[SELF]->[INDEX] == $_[SELF]->[SIZE] - 1;
}


sub item {
    $_[SELF]->[INDEX] < 0 || $_[SELF]->[INDEX] >= $_[SELF]->[SIZE]
        ? undef
        : $_[SELF]->[DATA]->[ $_[SELF]->[INDEX] ];
}


sub prev {
    $_[SELF]->[INDEX] < 1
        ? undef
        : $_[SELF]->[DATA]->[ $_[SELF]->[INDEX] - 1 ];
}

sub next {
    $_[SELF]->[INDEX] > $_[SELF]->[SIZE] - 2
        ? undef
        : $_[SELF]->[DATA]->[ $_[SELF]->[INDEX] + 1 ];
}


sub one {
    return $_[SELF]->[INDEX] < $_[SELF]->[SIZE] - 1
         ? $_[SELF]->[DATA]->[ ++$_[SELF]->[INDEX] ]
         : (undef, 1);
}

sub all {
    my $self = shift;

    if ($self->[INDEX] < 0) {
        $self->[INDEX] = $self->[SIZE]; 
        return $self->[DATA];
    }
    else {
        my $data  = $self->[DATA];
        my $slice = [
            @$data[ $self->[INDEX] + 1 .. $self->[SIZE] - 1 ]
        ];
        $self->[INDEX] = $self->[SIZE];
        return $slice;
    }
}

1;
__END__
        : (undef, 1);
    
    return $_[SELF]->[INDEX] < $_[SELF]
        return (undef, STATUS_DONE)
        unless $index < $max;
        
    $index++;

    @$self{ @ICFL }         # index, count, first, last
        = ( $index, $index + 1, 0, $index == $max ? 1 : 0 );
        
    @$self{ @PREV_NEXT }    # prev, next
        = @$data[$index - 1, $index + 1];

    return $data->[$index];

    

sub prepare {
    my $self  = shift;
    my $data  = $self->{ data } = $self->{ init };
    my $size  = scalar @$data;
    my $index = 0;

    $self->debug("preparing iterator: ", $self->dump_data_inline($data), "\n")
        if DEBUG;

    return undef
        unless $size;
    
    @$self{ @SMICFL }       # size, max, index, count, first last
        = ( $size, $size - 1, $index, 1, 1, $size > 1 ? 0 : 1, undef );
        
    @$self{ @PREV_NEXT }    # prev, next
        = (undef, $data->[$index + 1]);

    return $data
}


sub get_first {
    my $self = shift;
    my $data = $self->prepare
            || return (undef, STATUS_DONE);     # empty

    return $data->[0];
}


sub get_next {
    my $self = shift;
    my $data = $self->{ data } 
        || return $self->get_first;

    my ($max, $index) = @$self{ @MAX_INDEX };

    return (undef, STATUS_DONE)
        unless $index < $max;
        
    $index++;

    @$self{ @ICFL }         # index, count, first, last
        = ( $index, $index + 1, 0, $index == $max ? 1 : 0 );
        
    @$self{ @PREV_NEXT }    # prev, next
        = @$data[$index - 1, $index + 1];

    return $data->[$index];
}


sub get_all {
    my $self = shift;
    my $inc  = $self->{ data } ? 1 : 0;     # inc index if get_first has been called()
    my $data = $self->{ data }
            || $self->prepare
            || return (undef, STATUS_DONE);

    my ($max, $index) = @$self{ @MAX_INDEX };
    my @rest;

    $self->debug("index: $index  (+ inc: $inc)  max: $max") if DEBUG;

    # if there's still some data to go...
    if ($index + $inc <= $max) {
        # If get_first() has previously been called (i.e. $self->{ data }
        # is set) then $inc will contain 1 to indicate that we must increment
        # the index counter to step over the item already returned.
        $index += $inc;
        @rest = @$data[$index..$max];
        
        # update counters and flags
        @$self{ @ICFL }     # index, count, first, last
            = ( $max, $max + 1, 0, 1 );

        return \@rest;
    }
    else {
        return (undef, STATUS_DONE);
    }
}
    

#========================================================================
#                   -----  PRIVATE DEBUG METHODS -----
#========================================================================

#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string detailing the internal state of 
# the iterator object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    join('',
         "  Data: ", $self->{ _DATA  }, "\n",
         " Index: ", $self->{ INDEX  }, "\n",
         "Number: ", $self->{ NUMBER }, "\n",
         "   Max: ", $self->{ MAX    }, "\n",
         "  Size: ", $self->{ SIZE   }, "\n",
         " First: ", $self->{ FIRST  }, "\n",
         "  Last: ", $self->{ LAST   }, "\n",
         "\n"
     );
}


1;

__END__
