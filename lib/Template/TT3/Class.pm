package Template::TT3::Class;

use Badger::Class
    version   => 3.00,
    debug     => 0,
    uber      => 'Badger::Class',
    utils     => 'self_params camel_case',
    constants => 'ARRAY HASH CODE DELIMITER PKG BLANK',
    constant  => {
        CONSTANTS => 'Template::TT3::Constants',
        PATTERNS  => 'Template::TT3::Patterns',
#       CONFIG    => 'Template::TT3::Config',
        UTILS     => 'Template::TT3::Utils',
        BASE_OP   => 'Template::TT3::Element::Operator',
    },
    hooks => {
        patterns => \&patterns,
        generate => \&generate,
        subclass => \&subclass,
        alias    => \&alias,
    };

our $DEBUG_OPS = 0;


sub base_id {
    shift->{ name }->base_id;
}


sub patterns {
    my $self = shift;
    _autoload($self->PATTERNS)->export($self->{ name }, @_);
}


sub alias {
    my ($self, $params) = self_params(@_);
    
    while (my ($key, $value) = each %$params) {
        my $method = ref $value eq CODE
            ? $value
            : $self->method($value)
           || die "Invalid method specified for '$key' alias: $value";
        $self->method( $key => $method );
    }
    return $self;
}


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
            $spec = [base => $base, %$spec];
        }
        else {
            die "Invalid subclass specification for $pkg: $spec\n";
        }

        if ($pkg =~ s/^_//) {
            $pkg = $self.PKG.$pkg;
            _debug("found '_' at start, made it $pkg\n");
        }
        _debug("Generating subclass $pkg as { ", join(', ', @$spec), " }\n") if DEBUG;
        $self->generate($pkg => $spec);
    }
    
    return $self;
}


sub generate_ops {
    my $self = shift;
    my $spec = shift;
    my $args = @_ == 1 && ref $_[0] ? shift : [ @_ ];
    my $id   = $spec->{ id } || '';
       $id   = "${id}_" if $id;

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
                    as_expr => sub { 
                        shift->become($pre)->as_expr(@_);
                    },
                    as_postop => sub { 
                        shift->become($post)->as_postop(@_);
                    },
                },
            ]
        );
    }
}


sub generate_number_ops {
    shift->generate_ops(
        { id => 'num', methods => 'value values number text' },
        @_
    );
}


sub generate_number_assign_ops {
    shift->generate_ops(
        { id => 'num', methods => 'value values number' },
        @_
    );
}


sub generate_text_ops {
    shift->generate_ops(
        { id => 'txt', methods => 'value values text' },
        @_
    );
}


sub generate_text_assign_ops {
    shift->generate_ops(
        { id => 'txt', methods => 'value values' },
        @_
    );
}


sub generate_boolean_ops {
    shift->generate_ops(
        { id => 'bool', methods => 'value values' },
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

    class->generate_ops(
        { 
            methods => 'value values number text' 
        },
        {
            inc => prefix => sub {
                # code implementing 'inc' prefix operator
            },
            dec => prefix => sub {
                # code implementing 'dec' prefix operator
            }
        }
    );

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

See L<Template::TT3::Elements::Number> for an example of it in use.

=head2 generate_text_ops(%classes)

This method of convenience provides a wrapper around L<generate_ops()> to
provide the correct specification for creating text operators.  

    class->generate_text_ops(
        append => infix_left => sub {                           # a ~ b
            # code implementing 'append' infix operator
        },
    );

See L<Template::TT3::Elements::Text> for an example of it in use.

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
