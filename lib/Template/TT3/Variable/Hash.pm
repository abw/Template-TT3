package Template::TT3::Variable::Hash;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type  => 'hash',
    },
    alias     => {
        pairs => \&values,
    };


sub dot {
    my ($self, $name, $args) = @_;

    $self->debug(
        "hash lookup $name with args [$args] => ", 
        $self->dump_data($args)
    ) if DEBUG;

    # This is NFG.  It's just too damn inconvenient to have the virtual 
    # methods masking data items.  Things like hash.text, hash.size, etc
    # all resolve to virtual methods, not data.  The thing is, resolving
    # the VMs first is the more predictable way to do things.  VMs change
    # rarely, but data changes all the time.  If data resolved first then
    # you'll never be sure what hash.text resolves to.  At least this way,
    # hash.text *always* resolves to a virtual method, even if you weren't
    # expecting it to.  It's also what Javascript does.  That doesn't mean
    # we should necessarily do it, but there is at least a justification 
    # there for following a popular language that many of TT's target 
    # audience will be familiar with.  On the plus side, we'll eventually 
    # support hash{text} (and hash['text'], like JS) which will always 
    # resolve data items and never virtual methods.  Although it's not as
    # clean as hash.text it does at least provide a work-around.  Another
    # partial solution would be to severely limit the default set of hash
    # virtual methods.  We might be able to hit the sweet spot of having 
    # few enough VMs to be useful without blocking common data names (like
    # 'text' and 'size', to name just two).  Another possibility is to have
    # data resolve first and provide an explicit operator other than '.'
    # to resolve vmethods.  I'm not sure what the right thing to do is.
    
    
    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("hash vmethod: $name") if DEBUG;
        return $self->[CONTEXT]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
    else {
        return $self->[CONTEXT]->use_var( 
            $name,
            $self->[VALUE]->{$name}, 
            $self, 
            $args
        );
    }
}


sub dot_set {
    my ($self, $name, $value, $element) = @_;

    $self->debug(
        $self->fullname, "->dot_set($name => $value) ", 
        $element ? " by element $element" : " (no element)"
    ) if DEBUG;
    
    $self->[VALUE]->{ $name } = $value;

    return $self->[CONTEXT]->use_var( 
        $name,
        $value, 
        $self, 
    );
}


# NOTE - this is evaluating the hash in list (values) context, so it's 
# really equivalent to C<%hash>.  It is not the same thing as C<values %hash>

sub values {
    $_[SELF]->debug("values()") if DEBUG;
    return %{ $_[SELF]->[VALUE] }
}



    
1;
