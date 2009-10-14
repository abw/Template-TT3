package Template::TT3::Class;

use Badger::Class
    version   => 3.00,
    debug     => 0,
    uber      => 'Badger::Class',
    constants => 'ARRAY HASH DELIMITER',
    constant  => {
        CONSTANTS => 'Template::TT3::Constants',
        PATTERNS  => 'Template::TT3::Patterns',
        CONFIG    => 'Template::TT3::Config',
        UTILS     => 'Template::TT3::Utils',
    },
    hooks => {
        patterns => \&patterns,
        generate => \&generate,
        subclass => \&subclass,
    };


# Badger::Class uses this to determine what to strip off the front of the
# class name to generate a short id for a class (e.g. Badger::Example::Foo
# without the 'Badger' base_id ends up as example.foo).  We're going to 
# extend that concept to allow individual modules to define a base_id method 
# (rather than just Template::TT3::Class).  NOTE: this may change

sub base_id {
    shift->{ name }->base_id;
}



#-----------------------------------------------------------------------
# patterns(@symbols)
#
# Method to import symbols from Template::Patterns
#-----------------------------------------------------------------------

sub patterns {
    my $self = shift;
    _autoload($self->PATTERNS)->export($self->{ name }, @_);
}


#-----------------------------------------------------------------------
# method to generate a new class
#-----------------------------------------------------------------------

sub generate {
    my $self    = shift;
    my $classes = @_ == 1 && ref $_[0] ? shift : [ @_ ];
    my ($pkg, $spec);

    $classes = 
            ref $classes eq ARRAY ? [ @$classes ]     # a copy we can mutate
        :   ref $classes eq HASH  ? [ %$classes ]     # flatten hash to list
        : ! ref $classes          ? [ split(DELIMITER, $classes) ]
        :   die "Invalid class list specified to generate: $classes\n";

    while (@$classes) {
        # first item is a name, followed by optional hash ref of parameters
        $pkg  = shift @$classes;
        $spec = @$classes && ref $classes->[0]
            ? shift @$classes
            : { };
        $spec = ref $spec eq ARRAY ?    $spec
              : ref $spec eq HASH  ? [ %$spec ]
              : die "Invalid class specification for $pkg: $spec\n";
#        _debug("Generating $pkg as { ", join(', ', @$spec), " }\n");
        class->export($pkg => @$spec);
    }
    return $self;
}


#-----------------------------------------------------------------------
# method to generate a new subclass of the current class
#-----------------------------------------------------------------------

sub subclass {
    my $self = shift;
    my $base = $self->{ name };
    my $classes = @_ == 1 ? shift : [ @_ ];
    my ($pkg, $spec);

    $classes = 
            ref $classes eq ARRAY ? [ @$classes ]     # a copy we can mutate
        :   ref $classes eq HASH  ? [ %$classes ]     # flatten hash to list
        : ! ref $classes          ? [ split(DELIMITER, $classes) ]
        :   die "Invalid class list specified to generate: $classes\n";
        
#    _debug('classes: [', join(', ', @$classes), "]\n");

    while (@$classes) {
        # first item is a name, followed by optional hash ref of parameters
        $pkg  = shift @$classes;
        $spec = @$classes && ref $classes->[0]
            ? shift @$classes
            : { };
        if (ref $spec eq ARRAY) {
            unshift(@$spec, base => $base);
        }
        elsif (ref $spec eq HASH) {
            $spec->{ base } = $base;
            $spec = [%$spec];
        }
        else {
            die "Invalid subclass specification for $pkg: $spec\n";
        }
#        _debug("Generating subclass $pkg as { ", join(', ', @$spec), " }\n");
        $self->generate($pkg => $spec);
    }
    
    return $self;
}


sub _debug {
    print STDERR @_;
}
    
1;
__END__

=head1 NAME

Template::TT3::Class - class metaprogramming module

=head1 SYNOPSIS

    package Template::TT3::Example;
    
    use Template::TT3::Class
        version     => 3.00,             # sets $VERSION number
        debug       => 0,                # sets $DEBUG flag
        base        => 'Template::TT3::Base', # specify base class
        utils       => 'blessed UTILS';  # imports from Template::TT3::Utils
        # ...and more...

=head1 DESCRIPTION

L<Template::TT3::Class> is a class metaprogramming module derived from
L<Badger::Class>. You should read the documentation for L<Badger::Class>
first to understand the basic principles of what this module does.

The L<class()|Badger::Class/class()> subroutine can be used to fetch a
L<Template::TT3::Class> object for a package.

    package Template::TT3::Example;
    use Template::TT3::Class 'class';

You can use this object to perform various common class metaprogramming
tasks, like setting the version number, using a a debugging flag, defining a 
base class, and so on.

    # set version, base class and debug flag
    class->version(3.14);
    class->debug(1);
    class->base('Template::TT3::Base');

You can also use the import hooks to acheive the same effect.

    package Template::TT3::Example;
    
    use Template::TT3::Class
        version => 3.14,
        debug   => 1,
        base    => 'Template::TT3::Base';

=head1 METHODS

C<Template::TT3::Class> is a subclass of L<Badger::Class> and inherits all of 
its methods and other features.

In addition the following methods are also defined.

=head1 METHODS

=head2 config()

Method used to define a L<Template::TT3::Config> schema.  This will eventually
be moved into L<Badger::Config>.

=head2 patterns()

Method to import regular expression patterns from L<Template::TT3::Patterns>.
This is typically called as an import hook.

    package Template::TT3::Example;
    
    use Template::TT3::Class
        patterns => '$INTEGER';
    
    my $text = '123';
    
    if ($text =~ /$INTEGER/) {
        print "matched integer: $1\n";
    }

=head2 slots()

Method to define slot methods for list based objects.  Typically called
as an import hook.

    package Template::TT3::Example;
    
    use Template::TT3::Class
        slots => 'foo bar baz',
        base  => 'Template::TT3::Base';
    
    sub new {
        my $class = shift;
        bless [@_], $class;     # list-based object
    }
    
    package main;
    
    my $thing = Template::TT3::Example->new(10, 20, 30);
    print $thing->foo;      # 10
    print $thing->bar;      # 20
    print $thing->baz;      # 30

=head2 generate()

Method to generate other classes.  Typically called as an import hook.

    use Template::TT3::Class
        generate => {
            'Template::TT3::Example::One' => {
                version => 3.00,
                base    => 'Template::TT3::Base',
                methods => {
                    foo => sub { ... },
                    bar => sub { ... },
                },
                # plus any other Template::TT3::Class import hooks
            },
            'Template::TT3::Example::Two' => {
                ...
            }
        };

=head2 subclass()

Method to generate subclasses of the current class.  May be deprecated RSN.

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

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
