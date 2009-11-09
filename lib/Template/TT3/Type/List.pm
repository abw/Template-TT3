#========================================================================
#
# Template::TT3::Type::List
#
# DESCRIPTION
#   Object providing providing methods for manipulating lists.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Type::List;

use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Type',
    constant => {
        LIST => __PACKAGE__,
        type => 'List'
    },
    exports  => {
        any  => 'LIST List',
    };


our $METHODS   = {
    new      => \&new,
    
    # ref/type methods
    ref      => LIST->can('ref'),
    type     => LIST->can('type'),

    # constructor methods
    new      => \&new,
    clone    => \&clone,
    copy     => \&copy,

    # converter methods
    hash     => \&hash,
    list     => \&list,
    text     => \&text,
    join     => \&join,

    # accessor methods
    item     => \&item,
    first    => \&first,
    last     => \&last,
    max      => \&max,
    size     => \&size,

    # sorting, searching, slicing and dicing methods
    grep     => \&grep,
    sort     => \&sort,
    nsort    => \&nsort,
    unique   => \&unique,
    reverse  => \&reverse,
    slice    => \&slice,


    # mutator methods
    push     => \&push,
    pop      => \&pop,
    shift    => \&shift,
    unshift  => \&unshift,
    splice   => \&splice,
    merge    => \&merge,

#    # mutating methods
#    import   => \&import,

};


# TODO: get(), set(), any others?

*tt_expand = \&text;
*tt_set    = \&set;
*tt_get    = \&get;

sub List {
    # if we only have one argument and it's already LIST then return it,
    # otherwise forward all arguments to the LIST constructor.
    if (@_ == 1 && blessed($_[0]) && $_[0]->isa(LIST)) {
        return $_[0];
    }
    else {
        return LIST->new(@_) 
    };
}


#------------------------------------------------------------------------
# new()                                           [% List.new(a, b, c) %]
#
# Accepts a list reference which is blessed into a list object, or
# a list of items which are merged into a hash and blessed.
#------------------------------------------------------------------------

sub new {
    my $class = CORE::shift;
    $class = ref $class || $class;
    my $self;

    if (@_ && UNIVERSAL::isa($_[0], $class)) {
        # copy List object passed as argument
        $self = CORE::shift;
        $self = $self->copy(@_);
    }
    elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'ARRAY')) {
        # bless array passed as argument
        $self = CORE::shift;
    }
    else {
        # construct new array from list of named parameters
        $self = [ @_ ];
    }
    bless $self, $class;
}


#------------------------------------------------------------------------
# clone()                                                [% list.clone %]
#
# Returns a copy of the list blessed as another List object.
#------------------------------------------------------------------------

sub clone {
    my $self = CORE::shift;
    $self->new($self, @_);
}


#------------------------------------------------------------------------
# copy()                                                  [% list.copy %]
#
# Returns an unblessed copy of the list.
#------------------------------------------------------------------------

sub copy {
    my $self = CORE::shift;
    my $list = @_ && UNIVERSAL::isa($_[0], 'ARRAY') ? shift : [ @_ ];
    my $copy = [ @$self ];
    CORE::push(@$copy, @$list) if @$list;
    return $copy;
}


#------------------------------------------------------------------------
# hash()                                                  [% list.hash %]
#
# Returns a reference to a hash array constructed from the contents of 
# the list.
#------------------------------------------------------------------------

sub hash {
    my $self = CORE::shift;
    return { @$self };
}


#------------------------------------------------------------------------
# list()                                                  [% list.list %]
#
# Returns the list reference unmodified.
#------------------------------------------------------------------------

sub list {
    return $_[0];
}


#------------------------------------------------------------------------
# text()                                                  [% list.text %]
#
# Generate a text representation of the list.
#------------------------------------------------------------------------

sub text {
    my ($self, $joint) = @_;
    $joint = ', ' unless defined $joint;
    return CORE::join($joint, map { defined $_ ? $_ : '' } @$self);
}


#------------------------------------------------------------------------
# join($joint)                                      [% list.join(', ') %]
#
# Returns a string containing the items in the list joined together with 
# the joining delimiter passed as an argument or ' ' if undefined.
#------------------------------------------------------------------------

sub join {
    my ($self, $joint) = @_; 
    $joint = ' ' unless defined $joint;
    return CORE::join($joint, map { defined $_ ? $_ : '' } @$self);
}



#------------------------------------------------------------------------
# item($n)                                             [% list.item(3) %]
#
# Returns item $n in the list.  Returns first item if $n is unspecified.
#------------------------------------------------------------------------

sub item {
    my $self = CORE::shift;
    my $n = CORE::shift || 0;
    return @$self > $n ? $self->[$n] : undef;
}

sub get {
    $_[0]->[$_[1]];
}

sub set {
    $_[0]->[$_[1]] = $_[2];
}


#------------------------------------------------------------------------
# first($n)                                              [% list.first %]
#
# Returns the first item or a list of the first $n items in the list.
#------------------------------------------------------------------------

sub first {
    my $self = CORE::shift;
    
    # nothing in list
    return undef unless @$self;

    if (@_) {
        my $n = CORE::shift;
        $n = @$self if $n > @$self;
        return [ @$self[0..$n-1] ];
    }
    else {
        return $self->[0];
    }
}


#------------------------------------------------------------------------
# last($n)                                                [% list.last %]
#
# Returns the last item or a list of the last $n items in the list.
#------------------------------------------------------------------------

sub last {
    my $self = CORE::shift;
    
    # nothing in list
    return undef unless @$self;

    if (@_) {
        my $n = CORE::shift;
        $n = @$self if $n > @$self;
        return [ @$self[-$n..-1] ];
    }
    else {
        return $self->[-1];
    }
}


#------------------------------------------------------------------------
# max()                                                    [% list.max %]
#
# Returns the index of the last item in the list.
#------------------------------------------------------------------------

sub max {
    my $self = CORE::shift;
    return $#$self; 
}


#------------------------------------------------------------------------
# size()                                                  [% list.size %]
#
# Returns the size of the list.
#------------------------------------------------------------------------

sub size {
    my $self = CORE::shift;
    return scalar @$self; 
}


#------------------------------------------------------------------------
# grep($pattern)                                [% list.grep('\.png$') %]
#
# Returns a new list containing items from the list that match $pattern.
#------------------------------------------------------------------------

sub grep { 
    my ($self, $pattern) = @_;
    $pattern ||= '';
    return [ CORE::grep /$pattern/, @$self ];
}


#------------------------------------------------------------------------
# sort($field)                               [% list.sort('name') %]
#
# Returns a new list containing the list items in alphabetically 
# sorted order.  If a search field is passed as an argument and the 
# items in the list are hash references containing that key or objects
# supporting that method, then the appropriate value from the hash or
# value returned by calling the object method will be used as the sorting
# key.
#
# TODO: this should have named parameters field => $fieldname, or 
# order => 'alpha/number', or sort => $sortsub, etc.
#------------------------------------------------------------------------

sub sort {
    my ($self, $field) = @_;
    return $self unless $#$self;        # no need to sort 1 item lists

    if (defined $field) {               # Schwartzian Transform 
        return [ CORE::map  { $_->[0] } # for case insensitivity
                 CORE::sort { $a->[1] cmp $b->[1] }
                 CORE::map  { [ $_, lc( UNIVERSAL::can($_, $field) ? $_->$field() 
                                      : UNIVERSAL::isa($_, 'HASH') ? $_->{ $field } 
                                      : $_ ) ] }
                 @$self ];
    }
    else {
        return [ CORE::map  { $_->[0] }
                 CORE::sort { $a->[1] cmp $b->[1] }
                 CORE::map  { [ $_, lc $_ ] } 
                 @$self ];
    }
}


#------------------------------------------------------------------------
# nsort($field)                                    [% list.sort('age') %]
#
# As per sort() but sorting numerically.
#------------------------------------------------------------------------

sub nsort {
    my ($self, $field) = @_;
    return $self unless $#$self;        # no need to sort 1 item lists

    if ($field) {                       # Schwartzian Transform 
        return [ CORE::map  { $_->[0] }  # for case insensitivity
                 CORE::sort { $a->[1] <=> $b->[1] }
                 CORE::map  { [ $_, lc( UNIVERSAL::can($_, $field) ? $_->$field() 
                                      : UNIVERSAL::isa($_, 'HASH') ? $_->{ $field } 
                                      : $_) ] } 
                 @$self ];
    }
    else {
        return [ CORE::map  { $_->[0] }
                 CORE::sort { $a->[1] <=> $b->[1] }
                 CORE::map  { [ $_, lc $_ ] } 
                 @$self ];
    }
}


#------------------------------------------------------------------------
# unique()                                              [% list.unique %]
#
# Returns a new list with all duplicate entries removed.  Unlike the 
# Unix utility 'uniq', the list does not need to be pre-sorted.
# TODO: should we allow a field parameter like sort/nsort?
#------------------------------------------------------------------------

sub unique {
    my $self = CORE::shift;
    my %seen;
    return [ CORE::grep { ! $seen{$_}++ } @$self ];
}


#------------------------------------------------------------------------
# reverse()                                            [% list.reverse %]
#
# Returns a reference to an array containing the list items in reverse 
# order.
#------------------------------------------------------------------------

sub reverse {
    my $self = CORE::shift; 
    return [ CORE::reverse @$self ];
}


#------------------------------------------------------------------------
# slice($from, $to)                                      [% list.slice %]
#
# Returns a new list containing the item in the range $from .. $to.
#------------------------------------------------------------------------

sub slice {
    my $self = CORE::shift;
    return [ @$self ] unless @_;
    my $from = CORE::shift || 0;
    return [] if $from > $#$self;
    my $to = CORE::shift || $#$self;
    $to = $#$self if $to > $#$self;
    return [ @$self[$from..$to] ];
}


#------------------------------------------------------------------------
# push($a, $b, ...)                            [% list.push(a, b, ...) %]
#
# Pushes the arguments onto the list.  Returns the new number of items
# in the list.
#------------------------------------------------------------------------

sub push {
    my $self = CORE::shift;
    CORE::push(@$self, @_);
    # return nothing for now (may want to return list)
    return '';
}


#------------------------------------------------------------------------
# pop($n)                                                  [% list.pop %]
#
# Pops the last item from the list and returns it.  If $n is specified 
# then it pops the last $n items and returns them as a new list.
#------------------------------------------------------------------------

sub pop {
    my $self = CORE::shift;

    if (@_) {
        my $n = CORE::shift;
        $n = @$self if $n > @$self;
        return [ CORE::splice(@$self, -$n) ];
    }
    else {
        return CORE::pop(@$self);
    }
}


#------------------------------------------------------------------------
# shift($n)                                              [% list.shift %]
#
# Shifts the first item from the list and returns it.
#------------------------------------------------------------------------

sub shift {
    my $self = CORE::shift;

    if (@_) {
        my $n = CORE::shift;
        $n = @$self if $n > @$self;
        return [ CORE::splice(@$self, 0, $n) ];
    }
    else {
        return CORE::shift(@$self);
    }
}


#------------------------------------------------------------------------
# unshift($a, $b, ...)                      [% list.unshift(a, b, ...) %]
#
# Unshifts the arguments onto the list.  Returns number of items added.
#------------------------------------------------------------------------

sub unshift {
    my $self = CORE::shift;
    return unshift(@$self, @_);
}


#------------------------------------------------------------------------
# splice($offset, $length, $replace)        [% list.splice(0, 3, list) %]
# splice($offset, $length, $a, $b)          [% list.splice(0, 3, a, b) %]
#
# Just like Perl's splice(), splices $replace list (or list of items)
# into list at offset, replacing $length items.  $replace, $length and
# $offset are optional.  Returns list of items spliced out of list.
#------------------------------------------------------------------------

sub splice {
    my ($self, $offset, $length, @replace) = @_;

    if (@replace) {
        # @replace can contain a list of multiple replace items, or 
        # be a single reference to a list
        @replace = @{ $replace[0] }
            if @replace == 1 && UNIVERSAL::isa($replace[0], 'ARRAY');
        return [ CORE::splice @$self, $offset, $length, @replace ];
    }
    elsif (defined $length) {
        return [ CORE::splice @$self, $offset, $length ];
    }
    elsif (defined $offset) {
        return [ CORE::splice @$self, $offset ];
    }
    else {
        return [ CORE::splice(@$self) ];
    }
}


#------------------------------------------------------------------------
# merge($a, $b, $c, ...)                        [% list.merge(a, b, c) %]
#
# Merges the arguments onto the end of the list.  If an item is a list
# then its contents are pushed onto the list, otherwise the item itself.
#------------------------------------------------------------------------

sub merge {
    my $self = CORE::shift;
    CORE::push(@$self, map { UNIVERSAL::isa($_, 'ARRAY') ? @$_ : $_ } @_);
    return $self;
}


__END__



#------------------------------------------------------------------------
# old_hash()                                             [% list.hash %]
#
# Returns a reference to a hash containing each entry in the list keyed
# by its index number, e.g. { 0 => $self->[0]. 1 => $self->[1], ... }
#
#------------------------------------------------------------------------

# TODO: decide if we still want a method that does this, and what to call it?

sub old_hash {
    my $self = CORE::shift; 
    my $n = 0; 
    return { map { ($n++, $_) } @$self };
}





1;

__END__

=head1 NAME

Template::TT3::Type::List - list virtual object

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

Note: we use the term 'list' interchangeably with 'array' here.  Technically
speaking we mean "reference to an array" when we say "reference to a list"
and so on, but we don't worry too much about the distinction in TT land.

Note: all these methods can be called as subroutines, passing a reference to
an array as the first argument.

=head2 METHODS

=head3 new()

Constructor method to create a new List object.  A reference to a List
object, array or a list of parameters can be passed as argument(s) to
define the contents of the List object.  If a List object is passed as
an argument then it is first cloned.  If a reference to an array is
passed then it is blessed into a List object without being copied.  If
a list of parameters is passed then they are merged into a new array
which is then blessed and returned as a List object.

=head3 clone()

Creates a new List object as a copy of the current one.  A reference
to a List object, array or a list of argument can be passed to define
any additional data items to be added to the cloned List object.

=head3 ref()

Returns the string 'ARRAY', equivalent to Perl's ref() function.

=head3 type()

Returns the string 'List' to indicate the TT data type.

=head3 copy()

Returns a reference to an unblessed array containing a copy of
the current List object and any additional items passed by reference
to another list object, array or as a list of arguments.

=head3 hash()

TODO

=head3 list()

TODO

=head3 text($delim)

TODO

=head3 join($delim)

TODO

=head3 item()

TODO

=head3 first()

TODO

=head3 last()

TODO

=head3 max()

TODO

=head3 size()

TODO

=head3 grep()

TODO

=head3 sort()

TODO

=head3 nsort()

TODO

=head3 unique()

TODO

=head3 reverse()

TODO

=head3 slice()

TODO

--
=head3 MORE METHODS TODO

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 TODO

sort() and nsort() should take named parameters.

[% list.sort(field => 'name') %] rather than [% list.sort('name') %]

=head1 VERSION

$Revision: 1.2 $

=head1 COPYRIGHT

Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


