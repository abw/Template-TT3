package Template::TT3::Class;

use Badger::Debug ':all';
use Badger::Class
    version   => 3.00,
    debug     => 0,
    uber      => 'Badger::Class',
    base      => 'Badger::Base',
    utils     => 'self_params camel_case',
    constants => 'ARRAY HASH CODE DELIMITER PKG BLANK',
    constant  => {
        # TODO: change these to use Template::TT3::Modules constants
        CONSTANTS   => 'Template::TT3::Constants',
        MODULES     => 'Template::TT3::Modules',
        PATTERNS    => 'Template::TT3::Patterns',
#       CONFIG      => 'Template::TT3::Config',
        UTILS       => 'Template::TT3::Utils',
        AS_ROLE     => 'Template::TT3::Element::Role',
        BASE_OP     => 'Template::TT3::Element::Operator',
        VIEW_METHOD => 'view_%s',
    },
    hooks => {
        patterns    => \&patterns,
        modules     => \&modules,
        generate    => \&generate,
        subclass    => \&subclass,
        hub_methods => \&hub_methods,
        view        => \&view,
        as          => \&as,
    };


our $DEBUG_OPS = 0;


sub base_id {
    shift->{ name }->base_id;
}


sub modules {
    my $self = shift;
    _autoload($self->MODULES)->export($self->{ name }, @_);
}


sub patterns {
    my $self = shift;
    _autoload($self->PATTERNS)->export($self->{ name }, @_);
}


sub view {
    my ($self, $view) = @_;
    my $method = sprintf(VIEW_METHOD, $view);

    $self->method( 
        view => sub {
            $_[1]->$method($_[0]);
        }
    );
}


# TODO: this is being deprecated in favour of dedicated 
# Template::TT3::Class::Element subclass

sub as {
    my ($self, $roles) = @_;
    my $base = $self->AS_ROLE;

    $roles = [ split(DELIMITER, $roles) ]
        unless ref $roles eq ARRAY;

    $self->mixin( 
        map { $base.PKG.camel_case($_) } 
        @$roles 
    );
}


sub hub_methods {
    my ($self, $methods) = @_;

    $methods = [ split(DELIMITER, $methods) ]
        unless ref $methods eq ARRAY;

    $self->methods(
        map {
            my $name = $_;              # lexical copy for closure
            $name => sub {
                shift->hub->$name(@_);
            }
        }
        @$methods
    );
}


# I think the list_vars() in Badger::Class is broken.

sub list_vars {
    my $self = shift;               # must remove these from @_ here
    my $name = shift;
    my $vars = $self->all_vars($name);
    my (@merged, $list);
    
    # remove any leading '$' 
    $name =~ s/^\$//;

#    foreach $list (@_, @$vars) {    # use whatever is left in @_ here
    foreach $list ( reverse(@$vars), @_ ) { 
        next unless defined $list;
        if (ref $list eq ARRAY) {
            next unless @$list;
            push(@merged, @$list);
        }
        else {
            push(@merged, $list);
        }
    }

    return wantarray ? @merged : \@merged;

}


# don't think this is used any more

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


sub subclass {
    my ($self, $name, @spec) = @_;
    my $class = class( $self->{ name }.PKG.camel_case($name), ref $self )->base($self);
    $class->export(\@spec) if @spec;
    return $class;
}


# TODO: change this to generate_elements() because it's no longer specific
# to operators

sub generate_ops {
    my $self = shift;
    my $spec = shift;
    my $args = @_ == 1 && ref $_[0] ? shift : [ @_ ];
    my $id   = $spec->{ id } || '';
       $id   = "${id}_" if $id;             # err... this isn't being used

    # methods gives us a list of method names that we want to alias to
    my $methods = $spec->{ methods } || 'value';
    $methods = [ split(DELIMITER, $methods) ]
        unless ref $methods eq ARRAY;

    $args = 
        ref $args eq ARRAY ? [ @$args ]     # a copy we can mutate
      : ref $args eq HASH  ? [ %$args ]     # flatten hash to list
      : die "Invalid arguments provided to generate_ops() : $args";

    while (@$args) {
        # First item is name, then any mixin/base classes, followed by a
        # CODE reference which should be installed as the value() method,
        # with an alias of values() pointing at the same subroutine.
        my ($name, @bases, $base, $code);
        $name = shift @$args;
        $name = $self->{ name }.PKG.camel_case($name);
        
        # TODO: change these bases to mixin roles
        while (@$args && ! ref $args->[0]) {
            $base = shift @$args;
            push(
                @bases,
                $base =~ /::/
                    ? $base
                    : BASE_OP.PKG.camel_case($base)
            );
        }

        push(@bases, $self->{ name });
        
        die "No subroutine specified for $name in generate_ops()"
            unless @$args && ($code = shift @$args);

        die "Invalid subroutine specified for $name in generate_ops(); $code"
            unless ref $code eq CODE;

        if ($DEBUG_OPS) {
            # generate wrapper that calls debug_ops() before the real sub
            my $real = $code;
            $code = sub {
                $_[0]->debug_op($_[1]);
                $real->(@_);
            };
        };

#        _debug("generate_ops() $name => ", join(', ', @bases), "\n");
#        _debug("methods are : ", join(', ', @$methods), "\n");
        
        class->export(
            $name => [
                base    => \@bases,
                methods => {
                    map { $_ => $code }
                    @$methods
                }
            ]
        );
    }
    return $self;
}


sub generate_pre_post_ops {
    my ($self, $params) = self_params(@_);

    while (my ($key, $elements) = each %$params) {
        my $name = $self->{ name }.PKG.camel_case($key);
        my ($pre, $post) = @$elements;
        
        class->export(
            $name => [
                base    => $self->{ name },
                methods => {
                    parse_expr => sub { 
                        shift->become($pre)->parse_expr(@_);
                    },
                    parse_infix => sub { 
                        shift->become($post)->parse_infix(@_);
                    },
                },
            ]
        );
    }
}



sub generate_html_commands {
    shift->generate_ops(
        { id => 'html', methods => 'text value values' },
        @_
    );
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
        base        => 'Template::Base', # specify base class
        utils       => 'blessed';        # imports from Template::Utils
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

You can also use the import hooks to achieve the same effect.

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

=head2 base_id()

L<Badger::Class> uses this to determine what to strip off the front of the
class name to generate a short id for a class (e.g. C<Badger::Example::Foo>
without the C<Badger> base_id ends up as C<example.foo>).  We're going to 
extend that concept to allow individual modules to define a C<base_id()> 
method.

NOTE: this may be subject to change

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

=head2 alias($name,$method)

Creates an alias to an existing method.  The method may be defined in the 
current class or in a base class.

    class->alias( foo => 'bar' );       # foo() is now an alias for bar()

A code reference can also be passed to set a method directly.  In this case
the method performs the same as L<method()|Badger::Class/method()> in 
L<Badger::Class>.

    class->alias( 
        foo => sub { 
            ... 
        } 
    ); 

This method can be called as an export hook.

    package Template::TT3::Example;
    
    use Template::TT3::Class
        base  => 'Badger::Base',
        alias => {
            gen_msg => 'message',
        };

In the above example, a C<gen_msg()> alias is created in the
C<Template::TT3::Example> module which references the 
L<message()|Badger::Base/message()> method defined in the L<Badger::Base>
base class.

=head2 generate(%classes)

This method can be called to generate other classes.

    package Template::TT3::Example;
    
    use Template::TT3::Class
        import => 'class';
    
    class->generate(
        'Template::TT3::Example::Foo' => {
            version => 2.718,
            base    => 'Template::TT3::Example',
            methods => {
                wam => sub { ... },
                bam => sub { ... },
            }
            # plus any other Template::TT3::Class import hooks
        },
        'Template::TT3::Example::Bar' => {
            ...
        }
    );

The first argument is a class name.  The second argument is a reference to
a hash array or list of named parameters.  These can include any export 
hooks defined by L<Template::TT3::Class> or L<Badger::Class>. 

=head2 subclass(%classes)

This method can be used to create subclasses of the current class.

    package Template::TT3::Example;
    
    use Template::TT3::Class
        import => 'class';
    
    class->subclass(
        'Template::TT3::Example::Foo' => {
            version => 2.718,
            methods => {
                wam => sub { ... },
                bam => sub { ... },
            }
        }
    );

As per L<generate()>, the first argument is a class name and the second is a
reference to a hash array or list of named parameters giving the class
definition. The current class (C<Template::TT3::Example> in the example above)
will automatically be added as a base class of the new class
(C<Template::TT3::Example::Foo>).

=head2 generate_ops($spec,%classes)

This method can be used to generate a number of operator classes en masse.
It should be called from the base class package that you want to subclass
operators from.

    package Template::TT3::Element::Number;
    
    use Template::TT3::Class 'class';

    class->generate_ops(
        { 
            methods => 'value values number text' 
        },
        inc => prefix => sub {
            # code implementing 'inc' prefix operator
        },
        dec => prefix => sub {
            # code implementing 'dec' prefix operator
        }
    );

The first argument is a reference to a hash array containing any configuration
options that apply to all the subsequent operators. The remaining arguments 
specify the operators to be created.

Each operator starts with a short identified (e.g. C<inc>). This is CamelCased
(e.g. to C<Inc>) and appended to the base class name to give a new package
name (e.g. C<Template::TT3::Element::Number::Inc>). Any subsequent
non-reference arguments provide the names of operator base classes for the new
operator. These are CamelCased and appended to the
C<Template::TT3::Element::Operator> base class package (e.g. C<prefix> is
C<Template::TT3::Element::Operator::Prefix>, C<infix_right> is
C<Template::TT3::Element::Operator::InfixRight>, and so on) before being added
as base classes of the new operator. The final argument for an operator as a
code reference which implements an evaluation method for the operator.  This
is then installed into the new operator class as the methods listed in the 
C<methods> item of the C<$spec> (e.g. C<value()>, C<values()>, C<number()>
and C<text()> in this example).


=head2 generate_number_ops(%classes)

This method of convenience provides a wrapper around L<generate_ops()> to
provide the correct specification (the first argument passed to
L<generate_ops()>) for creating numeric operators.  

    class->generate_number_ops(
        inc => prefix => sub {
            # code implementing 'inc' prefix operator
        },
        dec => prefix => sub {
            # code implementing 'dec' prefix operator
        }
    );

Most numeric operators implement one single evaluation method, C<value()>,
which is then aliased to C<values()>, C<number()> and C<text()>.

See L<Template::TT3::Elements::Number> for an example of it in use.

=head2 generate_number_assign_ops(%classes)

Similar to L<generate_number_ops()>, this method creates new numerical
operator classes.

This method of convenience provides a wrapper around L<generate_ops()> to


=head2 generate_text_ops(%classes)

This method of convenience provides a wrapper around L<generate_ops()> to
provide the correct specification for creating text operators.  

    class->generate_text_ops(
        append => infix_left => sub {                           # a ~ b
            # code implementing 'append' infix operator
        },
    );

=head2 generate_pre_post_ops()

Used to generate intermediate classes that are used to switch between
two different operators depending on the parse context in which they are
used.  For example, the minus sign '-' can be used as a prefix operator
(negative) or an infix operator (subtraction).  

    package Template::TT3::Element::Number;
    use Template::TT3::Class 'class';
    
    class->generate_pre_post_ops(
        minus => ['num_negative', 'num_subtract'],
    )

The above code creates a new C<Template::TT3::Element::Number::Minus> class.
When used as a prefix operator (i.e. the C<parse_expr()> method is called on it)
the object will upgrade itself (via reblessing) to a
C<Template::TT3::Element::Number::Negative> object. When used as an infix
operator (or more generally any postfix operator, i.e. when C<parse_infix()> is
called) it will upgrade itself to a
C<Template::TT3::Element::Number::Subtract> object.

See L<Template::TT3::Elements::Number> for an example of it in use.

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
