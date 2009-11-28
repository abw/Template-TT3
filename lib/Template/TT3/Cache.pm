package Template::TT3::Cache;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Base',
    words     => 'SIZE',
    constants => ':cache',
    constant  => {
        PREV  => 0,
        NAME  => 1,
        DATA  => 2, 
        NEXT  => 3,
    },
    config    => [
        'size|cache_size|class:SIZE|method:CACHE_ALL',
    ],
    alias     => {
        destroy => \&clear,
    };


sub init {
    my ($self, $config) = @_;

    $self->debug("init() with ", $self->dump_data($config)) if DEBUG;

    $self->configure($config);
    $self->{ slot } = { };                      # slot lookup by name
    $self->{ used } = 0;                        # number of slots used

    return $self;
}


sub set {
    my ($self, $name, $data) = @_;
    my $size = $self->{ size };
    my ($head, $slot);

    return $self->error("name not defined from ", join(', ', caller(0)), "\n")
        unless defined $name;

    if ($size == CACHE_ALL) {
        # no size limit so cache everything directly in slot hash.
        # NOTE: this is an optimisation which changes the shape of the data
        # stored in the cache so you can't change the size once a cache is live
        $self->debug("adding data to cache for '$name'\n") if DEBUG;
        $self->{ slot }->{ $name } = \$data;    # store ref so always true
        return 1;
    }
    elsif ($size == CACHE_NONE) {
        # cache size of 0 indicates no caching, also treat any other negative
        # numbers (other than the special CACHE_UNLIMITED value of -1) as 0
        return 0;
    }
    
    # at this point we know we have a positive, non-zero cache size
    
    if ($slot = $self->{ slot }->{ $name }) {
        # we 've got an existing slot for the name provided so we store the
        # new data in the old slot and pull it out of it's current position
        # in the list ready to add at the head below
        $self->debug("recycling existing cache slot for '$name'\n") if DEBUG;
        $self->_remove_slot($slot);
        $slot->[ DATA ] = $data;
    }
    elsif ($self->{ used } >= $size) {
        # all slots are filled so recycle the least recently used
        $self->debug("recycling oldest cache slot '$self->{tail}->[NAME]' for '$name'\n") if DEBUG;
            
        # remove the last slot (least recently used)
        $slot = $self->_remove_slot($self->{ tail });

        # delete old slot lookup entry and add a new one
        delete $self->{ slot }->{ $slot->[ NAME ] };
        $self->{ slot }->{ $name } = $slot;

        # add the name and data to the slot
        $slot->[ NAME ] = $name;
        $slot->[ DATA ] = $data;
    }
    else {
        # we're under the size limit so create a new slot
        $self->debug("adding new cache slot for '$name'\n") if DEBUG;
        $slot = [ undef, $name, $data, undef ];
        $self->{ slot }->{ $name } = $slot;
        $self->{ used }++;
    }

    # add slot to head of list to indicate most recently used
    $self->_insert_slot($slot);
    
    return 1;
}


sub get {
    my ($self, $name) = @_;

    # fetch slot by name
    my $slot = $self->{ slot }->{ $name }
        || return $self->decline("not found in cache: $name");

    # if size is unlimited then the cache holds a reference to the 
    # original data rather than a slot record
    return $$slot
        if $self->{ size } == CACHE_ALL;

    # otherwise cache is size limited so we need to move the slot up to
    # the head of list (if it's not already there) to indicate that it 
    # has been used most recently
    unless($self->{ head } == $slot) {
        $self->_remove_slot($slot);
        $self->_insert_slot($slot);
    }

    return $slot->[ DATA ];
}


sub clear {
    my $self = shift;
    my ($slot, $next);

    $self->debug("clearing cache slots\n") if DEBUG;

    $slot = $self->{ head };

    while ($slot) {
        $next = $slot->[ NEXT ];
        undef $slot->[ PREV ];
        undef $slot->[ NEXT ];
        $slot = $next;
    }
    undef $self->{ head };
    undef $self->{ tail };
    $self->{ used } = 0;
}


# get, set, remove, size, purge, and clear

sub _insert_slot {
    my ($self, $slot) = @_;
    my $head = $self->{ head };

    # add slot at head of list, pointing forwards to old head
    $head->[ PREV ] = $slot if $head;
    $slot->[ NEXT ] = $head;
    $slot->[ PREV ] = undef;
    $self->{ head } = $slot;
    $self->{ tail } = $slot unless $self->{ tail };

    return $slot;
}


sub _remove_slot {
    my ($self, $slot) = @_;
    my $prev;

    # fix link from previous slot forward to this slot
    if ($prev = $slot->[ PREV ]) {
        $prev->[ NEXT ] = $slot->[ NEXT ];
        $slot->[ PREV ] = undef;
    }
    else {
        $self->{ head } = $slot->[ NEXT ];
    }

    # fix link from next slot backward to this slot
    if ($slot->[ NEXT ]) {
        $slot->[ NEXT ]->[ PREV ] = $prev;
        $slot->[ NEXT ] = undef;
    }
    else {
        $self->{ tail } = $prev;
    }

    return $slot;
}


sub _slot_report {
    my $self   = shift;
    my $output = '';
    my $slot   = $self->{ head };
    
    return $self->not_implemented('for unlimited size cache')
        if $self->{ size } == CACHE_ALL;

    while ($slot) {
        my ($prev, $name, $data, $next) = @$slot;
        my $prevname = $prev ? $prev->[NAME] : '<NULL>';
        my $nextname = $next ? $next->[NAME] : '<NULL>';
        $output .= "$prevname <-- [$name] --> ${nextname}\n";
        $slot = $next;
    }
    $output .= "tail: $self->{ tail }->[NAME]\n";
    return $output;
}


sub DESTROY {
    shift->destroy;
}


1;

__END__

=head1 NAME

Template::TT3::Cache - in-memory cache for template components

=head1 SYNOPSIS

    use Template::TT3::Cache;
    
    my $cache = Template::TT3::Cache->new( size => 32 );
    
    $cache->set( foo => $foo );
    
    # ...later...
    
    $foo = $cache->get('foo')
        || warn "foo has expired from cache\n";

=head1 DESCRIPTION

The C<Template::TT3::Cache> module implements a simple in-memory cache for
compiled template documents.

The most time-consuming part of processing a template is the initial phase in
which we read in the template source, parse it, and compile it into Perl code.
The Perl code is then evaluated and should result in an object being created
which implements the functionality of the original template. Fortunately, we
only need to compile the template once and can then re-use the generated
object as many times as we like.

C<Template::TT3::Cache> provides a simple mechanism for limiting the number of
templates that are cached and automatically discards the least-recently-used
component when the limit is reached.

It also defines a simple API and can act as a base class for modules that
implement different caching mechanisms. The API is deliberately compatible
with the L<Cache::Cache> modules, allowing you to use any of them as a direct
replacement for C<Template::TT3::Cache>.

=head1 METHODS

The following methods are implemented in addition to those inherited from the 
L<Template::TT3::Base> and L<Badger::Base> base classes.

=head2 new()

Constructor method which creates a new C<Template::TT3::Cache> object.  

    use Template::TT3::Cache;
    
    my $cache = Template::TT3::Cache->new();

The C<size> parameter (or C<cache_size> if you prefer your parameters a little
more long-winded) can be specified to define a limit to the number of items
that the cache will store at any one time.

    my $cache = Template::TT3::Cache->new( size => 32 );        # either
    my $cache = Template::TT3::Cache->new( cache_size => 32 );  # or

Set C<size> to C<0> to explicitly disable any caching.

    my $cache = Template::TT3::Cache->new( size => 0 );

The default C<size> value is C<-1> which indicates an unlimited size for the
cache. The L<Template::TT3::Constants> module defines the C<CACHE_ALL>
constant for this value.

    use Template::TT3::Constants 'CACHE_ALL';
    
    my $cache = Template::TT3::Cache->new( size => CACHE_ALL );

The C<CACHE_NONE> (0) constant is also provided for completeness.

    use Template::TT3::Constants 'CACHE_NONE';
    
    my $cache = Template::TT3::Cache->new( size => CACHE_NONE );

You can import both C<CACHE_NONE> and C<CACHE_ALL> by specifying the C<:cache>
constant group.

    use Template::TT3::Constants ':cache';

=head2 set($name, $component)

Add an item to the cache.  The first argument provides a name for the
component passed as the second argument, by which it can subsequently
be fetched via the C<get()> method.

    $cache->set( foo => $foo_component );

=head2 get($name)

Fetch an item from the cache previously stored by calling C<set()>.
If the item is not in the cache, either because it was never been 
put in the cache or because it was, but has subsequently expired, 
then the method returns C<undef>.

=head2 clear()

This method deletes all items from the cache and frees the memory associated
with the cache slots. It is called automatically by the L<DESTROY> method when
the cache object goes out of scope.

For the technically minded, the Least-Recently-Used algorithm implements a
doubly linked list of slots. Perl cannot free this data structure
automatically due to the circular references between the forward (C<NEXT>) and
backward (C<PREV>) references. This method walks the list explciitly deleting
all the C<NEXT/PREV> references, allowing the proper cleanup to occur and
memory to be repooled.

=head2 destroy()

This is an alias to the C<clear()> method in keeping with other TT3 modules
that follow that convention.  It is called automatically by the C<DESTROY>
method when the cache object goes out of scope and is garbage collected.

You can manually call the C<destroy()> method if you want to, but you probably
shouldn't ever need to.

=head1 INTERNAL METHODS

=head2 _insert_slot(\@slot)

Internal method to insert a cache slot at the head of the linked list.
New slots are always inserted at the head of the list.  Each time an 
entry is fetched from the cache, we remove the slot from its current
position in the list and re-insert it at the head.  Thus, the list remain
sorted in most-recently-used to least-recently-used order.

    # first and last items in slot are prev/next references which the
    # _insert_slot() method will fill in
    $self->_insert_slot([undef, $name, $data, undef]);

=head2 _remove_slot(\@slot)

Internal method to remove a slot from the linked list.

    $self->_remove_slot($slot);

=head2 DESTROY

Perl calls this method automatically when the cache object goes out of
scope.  In turn it calls the L<destroy()> method which is a simple alias to 
the L<clear()> method which releases the memory retained by the cache slots.

Subclasses may want to define the L<destroy()> method to implement different
or additional behaviour.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ROADMAP

This module will become C<Template::Cache> when TT3 is finally released.

=head1 SEE ALSO

L<Template::TT3::Base>, L<Badger::Base>.

See L<Cache::Cache> for various different caching modules that implement
different caching strategies and can be used in place of
C<Template::TT3::Cache>.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


