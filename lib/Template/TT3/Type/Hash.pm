#========================================================================
#
# Template::TT3::Type::Hash
#
# DESCRIPTION
#   Virtual object providing providing methods for manipulating hash 
#   arrays.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Type::Hash;

use warnings;
use strict;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Type',
    utils     => 'blessed',
    codec     => 'html',
    constants => 'SPACE BLANK',
    constant  => {
        HASH  => __PACKAGE__,
        type  => 'Hash',     # capitalised because it's a format type (of sorts)
    },
    exports   => {
        any   => 'HASH Hash',
        fail  => \&export_hash_function,
    },
    messages  => {
        bad_export => 'Invalid hash function specified to import: %s',
    };


our $METHODS   = {
    # ref/type methods
    ref         => __PACKAGE__->can('ref'),
    type        => \&type,

    # constructor methods
    new         => \&new,
    clone       => \&clone,

    # converter methods
    copy        => \&copy,
    hash        => \&hash,
    list        => \&list,
    
    # Oh fuck.  If vmethods mask values then you'll never be able to have a
    # hash.text item which is just plain stupid.
#    text        => \&text,
    as_text        => \&text,

    # inspector methods
    size        => \&size,
    each        => \&each,
    keys        => \&keys,
    values      => \&values,
    kvhash      => \&kvhash,
    kvlist      => \&kvlist,
    html_attrs  => \&html_attrs,

    # accessor methods
    item        => \&item,
    exists      => \&exists,
    defined     => \&defined,

    # sorting methods
    sort        => \&sort,
    nsort       => \&nsort,

    # mutating methods
    delete      => \&delete,
    import      => \&hash_import,
};


# TODO: generalise this and move it into type base class so all types can use it.

sub export_hash_function {
    my ($class, $target, $symbol, $more_symbols) = @_;
    my $name = $symbol;
    $name =~ s/^hash_//g;         # optional hash_ prefix
    my $method = $METHODS->{ $name }
        || return $class->error_msg( bad_export => $symbol );
    $class->export_symbol($target, $symbol, $method);
    return 1;
}

# For references - we need to do a final cleanup to make sure we've got as 
# much backward compatibiity as possible.

#our $TT2_HASH_VMETHODS = {
#    item    => \&hash_item,
#    hash    => \&hash_hash,
#    size    => \&hash_size,
#    each    => \&hash_each,
#    keys    => \&hash_keys,
#    values  => \&hash_values,
#    items   => \&hash_items,
#    pairs   => \&hash_pairs,
#    list    => \&hash_list,
#    exists  => \&hash_exists,
#    defined => \&hash_defined,
#    delete  => \&hash_delete,
#    import  => \&hash_import,
#    sort    => \&hash_sort,
#    nsort   => \&hash_nsort,
#};
#


our $SPLIFF = '=';
our $JOINT  = ', ';

# TODO: get(), set(), any others?

*tt_expand = \&text;
*tt_set    = \&set;
*tt_get    = \&get;

sub Hash {
    # if we only have one argument and it's already HASH then return it,
    # otherwise forward all arguments to the HASH constructor.
    if (@_ == 1 && blessed($_[0]) && $_[0]->isa(HASH)) {
        return $_[0];
    }
    else {
        return HASH->new(@_) 
    };
}



#------------------------------------------------------------------------
# new()                                        [% Hash.new(a=10, b=20) %]
#
# Accepts a hash reference which is blessed into a hash object, or
# a list of named parameters which are merged into a hash and blessed.
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my $self;

    if (@_ && UNIVERSAL::isa($_[0], $class)) {
        # copy Hash object passed as argument
        $self = shift;
        $self = $self->copy(@_);
    }
    elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'HASH')) {
        # bless hash array passed as argument
        $self = shift;
    }
    else {
        # construct new hash array from list of named parameters
        $self = { @_ };
    }
    bless $self, $class;
}


#------------------------------------------------------------------------
# clone()                                                [% hash.clone %]
#
# Returns a copy of the hash blessed as another Hash object.
#------------------------------------------------------------------------

sub clone {
    my $self = shift;
    $self->new($self, @_);
}


#------------------------------------------------------------------------
# copy()                                                  [% hash.copy %]
#
# Returns an unblessed copy of the hash.
#------------------------------------------------------------------------

sub copy {
    my $self = shift;
    my $hash = @_ && UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
    return { %$self, %$hash };
}



#------------------------------------------------------------------------
# hash()                                                  [% hash.hash %]
#
# Returns a reference to the hash array/object unmodified.
#------------------------------------------------------------------------

sub hash {
    return $_[0];
}


#------------------------------------------------------------------------
# list()                                                  [% hash.list %]
#
# Returns the hash reference as the single item in a list.
#------------------------------------------------------------------------

sub list {
    return [ $_[0] ];
}


#------------------------------------------------------------------------
# text()                                             [% hash.text %]
#
# Generate a text representation of the hash.
#------------------------------------------------------------------------

sub text {
    my ($self, $spliff, $joint) = @_;
    $spliff = $SPLIFF unless defined $spliff;
    $joint  = $JOINT  unless defined $joint;
    return join($joint, map {
        my $val = $self->{ $_ };
        $val = '' unless defined $val;
        "$_$spliff$val";
    } sort keys %$self);
}


#------------------------------------------------------------------------
# size()                                                  [% hash.size %]
#
# Returns the nubmer of key/value pairs in the hash.
#------------------------------------------------------------------------

sub size {
    my $self = shift;
    return scalar CORE::keys %$self;
}


#------------------------------------------------------------------------
# each()                                                  [% hash.each %]
#
# Returns the hash keys and values flattened to a list.
#------------------------------------------------------------------------

sub each {
    my $self = shift;
    return [ %$self ] unless @_;
    my $code = shift;
    my @out;
    while (my ($key, $value) = each %$self) {
        push(@out, $code->({ key => $key, value => $value }));
    }
    return \@out;
}


#------------------------------------------------------------------------
# keys()                                                  [% hash.keys %]
#
# Returns a list of the hash keys.
#------------------------------------------------------------------------

sub keys { 
    my $self = shift;
    [ CORE::keys %$self ]
}


#------------------------------------------------------------------------
# values()                                              [% hash.values %]
#
# Returns a list of the hash values.
#------------------------------------------------------------------------

sub values {
    my $self = shift;
    [ CORE::values %$self ];
}


#------------------------------------------------------------------------
# kvhash()                                              [% hash.kvhash %]
#
# Returns a reference to a list containing references to hash arrays, 
# each of which contains a key and value from the hash array.
#------------------------------------------------------------------------

sub kvhash {
    my $self = shift;
    [ map { { key => $_, value => $self->{ $_ } } } CORE::keys %$self ];
}


#------------------------------------------------------------------------
# kvlist()                                              [% hash.kvlist %]
#
# Returns a reference to a list containing references to lists, each of 
# which contains a key and value from the hash array.
#------------------------------------------------------------------------

sub kvlist {
    my $self = shift;
    [ map { [ $_, $self->{ $_ } ] } CORE::keys %$self ];
}


sub html_attrs {
    my $self  = shift;
    my @attrs = map {
        $_ . '="' . encode($self->{ $_ }) . '"'
    } 
    CORE::sort(CORE::keys(%$self));

    return @attrs
        ? SPACE . join(SPACE, @attrs)
        : BLANK;
}


#------------------------------------------------------------------------
# item($key)                                       [% hash.item('foo') %]
#
# Returns the item in the hash corresponding to the key passed as an 
# argument.
#------------------------------------------------------------------------

sub item {
    my ($self, $key) = @_; 
    $key = '' unless defined $key;
    $self->{ $key };
}

sub get {
#    $_[0]->debug('get ', join(', ', @_), " => ", $_[0]->{$_[1]}, "\n");
    $_[0]->{$_[1]};
}

sub set {
#    $_[0]->debug('set ', join(', ', @_), "\n");
    $_[0]->{$_[1]} = $_[2];
}


#------------------------------------------------------------------------
# exists($key)                                   [% hash.exists('foo') %]
#
# Returns true if the $key specified exists in the hash.
#------------------------------------------------------------------------

sub exists {
    my ($self, $key) = @_; 
    $key = '' unless defined $key;
    CORE::exists $self->{ $key };
}


#------------------------------------------------------------------------
# defined($key)                                 [% hash.defined('foo') %]
#
# Returns true if the $key specified is defined in the hash.
#------------------------------------------------------------------------

sub defined {
    my ($self, $key) = @_; 
    $key = '' unless defined $key;
    CORE::defined $self->{ $key };
}


#------------------------------------------------------------------------
# sort()                                                  [% hash.sort %]
#
# Returns the keys of the hash alphabetically sorted according to the 
# values.
#------------------------------------------------------------------------

sub sort {
    my $hash = shift;
    [ CORE::sort { lc $hash->{$a} cmp lc $hash->{$b} } (CORE::keys %$hash) ];
}


#------------------------------------------------------------------------
# nsort()                                                [% hash.nsort %]
#
# Returns the keys of the hash numerically sorted according to the 
# values.
#------------------------------------------------------------------------

sub nsort {
    my $hash = shift;
    no warnings;
    [ CORE::sort { $hash->{$a} <=> $hash->{$b} } (CORE::keys %$hash) ];
}


#------------------------------------------------------------------------
# delete($key)                                     [% hash.delete(key) %]
#
# Deletes the entry in the hash indexed by the key passed as an argument.
# Returns the value deleted, if any.
#------------------------------------------------------------------------

sub delete {
    my ($self, $key) = @_; 
    $key = '' unless defined $key;
    CORE::delete $self->{ $key };
}


#------------------------------------------------------------------------
# import($newhash)                        [% hash.import(newhash) %]
#
# Imports the values in the hash passed by reference as the $newhash 
# argument into the current hash.
#------------------------------------------------------------------------

sub hash_import {
    my $self = shift;
    return unless CORE::ref $self;    # ignore call at load time by use
    my $hash = @_ && UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
    @$self{ CORE::keys %$hash } = CORE::values %$hash;
    return $self;
}


1;

__END__

=head1 NAME

Template::TT3::Type::Hash - hash virtual object

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

Note: we use the term 'list' interchangeably with 'array' here.  Technically
speaking we mean "reference to an array" when we say "reference to a list"
and so on, but we don't worry too much about the distinction in TT land.

Note: all these methods can be called as subroutines, passing a reference to
a hash array as the first argument.

    my $hash = Template::TT3::Type::Hash->new( a => 10 );
    $hash->keys();  # [ a ]

    my $data = { b => 20 };
    Template::TT3::Type::Hash::keys($data);   # [ b ]

    # lookup method from hash object, pass raw hash data as argument
    $hash->can('keys')->($data);            # [ b ]

=head2 METHODS

=head3 new()

Constructor method to create a new hash array.  A reference to a Hash
object, hash array or a list of named parameters can be passed as
argument(s) to define the contents of the Hash object.  If a Hash
object is passed as an argument then it is first cloned.  If a
reference to a hash array is passed then it is blessed into a Hash
object without being copied.  If a list of named parameters is passed
then they are merged into a new hash array which is then blessed and
returned as a Hash object.

=head3 clone()

Creates a new Hash object as a copy of the current one.  A reference
to a Hash object, hash array or a list of named parameters can be
passed as argument(s) to define any additional data items to be added
to the cloned Hash object.

=head3 copy()

Returns a reference to an unblessed hash array containing a copy of
the current Hash object and any additional items passed by reference
to another Hash object, hash array or as a list of named parameters.

=head3 ref()

Returns the string 'HASH', equivalent to Perl's ref() function.

=head3 type()

Returns the string 'Hash' to indicate the TT data type.

=head3 hash()

Returns the Hash object unchanged, effectively a null operation.

=head3 list()

Returns a reference to a list containing the Hash object as a single item.

=head3 text($keyval_delim,$items_delim)

Returns a text representation of the hash array.  One or two optional 
arguments can be provided.  The first is used to define a delimiter to 
be used between key/value pairs.  The default value is C< =E<gt> >.
The second argument can be used to provide an alternate delimiter to be
used between successive pairs of items.  The default value is
C<, >.

=head3 keys()

Returns a reference to a list containing the keys of the hash array,
as per Perl's keys() function.

=head3 values()

Returns a reference to a list containing the values of the hash array,
as per Perl's values() function.

=head3 each()

Returns a reference to a list containing the interleaved keys and
values of the hash array.

=head3 kvlist()

Returns a reference to a list containing references to lists, each of which 
contains a key and value from the hash array.

=head3 kvhash()

Returns a reference to a list containing references to hash arrays,
each of which contains a key and value from the hash array.

=head3 item($key)

TODO

=head3 exists($key)

TODO

=head3 defined($key)

TODO

=head3 sort()

Sorts the I<values> in the hash array alphabetically and returns a
list of I<keys> corresponding to that order.  If you want a list of
keys in sorted order, then simply call the keys() method and sort the
values returned. 

=head3 nsort()

As per sort(), but returns the keys corresponding to the values sorted
numerically.  

=head3 delete($key)

Delete an item from the hash.

=head3 import($hash)

Import the contents of another hash.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

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


