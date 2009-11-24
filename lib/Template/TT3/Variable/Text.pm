package Template::TT3::Variable::Text;

use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Template::TT3::Variable',
    constants => ':type_slots',
    constant  => {
        type  => 'text',
    };



sub dot {
    my ($self, $name, $args) = @_;

    $self->debug(
        "text lookup $name with args [$args] => ", 
        $self->dump_data($args)
    ) if DEBUG;

    if (my $method = $self->[META]->[METHODS]->{ $name }) {
        $self->debug("text vmethod: $name") if DEBUG;
        return $self->[CONTEXT]->use_var( 
            $name,
            $method->($self->[VALUE], $args ? @$args : ()),
            $self
        );
    }
    else {
        return $self->no_method($name);
    }
}


# NOTE - this is evaluating the hash in list (values) context, so it's 
# really equivalent to C<%hash>.  It is not the same thing as C<values %hash>
#

sub pairs {
    $_[SELF]->debug("values()") if DEBUG;
    return ($_[SELF]->name, $_[SELF]->[VALUE]);
}

1;
