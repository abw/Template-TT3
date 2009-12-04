package Template3;

use 5.6.1;
use Template::TT3::Class
    version  => 2.71,
    debug    => 0,
    base     => 'Template::TT3::Base Badger::Prototype',
    import   => 'class',
    words    => 'ENGINE PROTOTYPE',
    auto_can => 'engine_can',
    messages => {
        no_engine     => 'No engine module is defined',
        no_module     => "Missing module name following '%s' import parameter",
        engine_object => 'Cannot set back-end to %s for an existing %s object',
    },
    exports  => {
        hooks => {
#           Template => \&_template_hook,
            engine   => \&_engine_hook,
            TT2      => \&_TT2_hook,
            TT3      => \&_TT3_hook,
            as       => [\&_as_hook, 1],
        },
        fail => \&_delegate_hook,
    };

our $ENGINES = {
    TT2     => 'Template::TT3::Engine::TT2',
    TT3     => 'Template::TT3::Engine::TT3',
    default => 'Template::TT3::Engine::TT3',
    
    # merge in any pre-defined engines
    defined $ENGINES ? %$ENGINES : () 
};

our $ENGINE = $ENGINES->{ default };
    


#-----------------------------------------------------------------------
# Define the hooks for import arguments that can be specified when the 
# Template3 module is loaded, 
# e.g. 
#   use Template3 engine => 'TT3';
#   use Template3 engine => 'My::Engine';
#   use Template3 as 'Template';
#   use Template3 'TT2'     # sugar for: use Template engine => 'TT2';
#   use Template3 'TT3'     # sugar for: use Template engine => 'TT3';
#-----------------------------------------------------------------------

sub _engine_hook { 
    my ($class, $target, $symbol, $symbols) = @_;

    my $module = shift(@$symbols) 
        || return $class->error_msg( no_module => $symbol );
    
    # feed it through the ENGINES map to expand aliases
    $module = $ENGINES->{ $module } || $module;

    # install the module as the current back-end engine
    $class->engine($module);

    # delegate any further import symbols to the back-end engine
    $module->export($target, $symbols);
}


sub _TT2_hook {
    my ($class, $target, $symbol, $symbols) = @_;
    unshift(@$symbols, engine => 'TT2', as => 'TT2');
}


sub _TT3_hook {
    my ($class, $target, $symbol, $symbols) = @_;
    unshift(@$symbols, engine => 'TT3', as => 'TT3');
}


sub _as_hook {
    my ($class, $target, $symbol, $alias, $symbols) = @_;
    my $engine = $class->engine;
    $class->debug("creating $alias to $engine");
#    unshift(@$symbols, engine => 'TT3', as => 'TT3' );
}


#-----------------------------------------------------------------------
# Define another hook that is called whenever we encounter import arguments
# that we can't handle ourselves.  This delegates them to the back-end engine
# module.
#-----------------------------------------------------------------------

sub _delegate_hook {
    my ($class, $target, $symbol, $symbols) = @_;
    unshift(@$symbols, $symbol);
    print "**DELEGATING** $symbols->[0] to engine\n";
    $class->engine->export($target, $symbols);
}



#-----------------------------------------------------------------------
# A method to get/set the current engine module.  Usually called as a class
# method via the 'engine' hook defined above.  Can also be called directly 
# as a class method.
# e.g. 
#    Template->engine('Template::TT3')>
#
# It can also be called as an object method, in which case it acts as an 
# assertion that the object is an instance (or subclass) of the engine class 
# provided as an argument.  
# e.g.
#    $object->engine('Template::TT3');      # returns true or dies
# 
# When called without any arguments it returns the current $ENGINE (for 
# class methods) or object type (for object methods).
#-----------------------------------------------------------------------

sub engine {
    my $self   = shift;
    my $class  = $self->class;
    my $type;

    # TODO: should ask Engines for Engine to handle name mapping.

    if (@_) {
        # Got an argument: the engine $type.  It can be a specific module
        # name or an alias defined in $ENGINES
        $type = shift;
        $type = $ENGINES->{ $type } || $type;
        
        if (ref $self) {
            # when called as an object method, assert that the object isa $type
            return $self->isa($type)
                 ? 1
                 : $self->error_msg( engine_object => $type, $class );
        }
        else {
            # when called as a class method, install the engine by updating
            # the relevant class vars (skip if engine is already installed)
            if ($class->var(ENGINE) eq $type) {
                return $type;
            }
            else {
                $class->debug("Set $class ENGINE to $type\n") if DEBUG;
                class($type)->load;     # load the module
                $type = $type->load;    # call its load method
                $class->var(ENGINE, $type);
                $class->var(PROTOTYPE, undef);
                return $type;
            }
        }
    }
    elsif (ref $self) {
        # got no arguments for an object method so return object class
        return $class;
    }
    else {
        # got no arguments for class method, so look for $ENGINE in this
        # class or any superclass and make sure the module is loaded up
        $type = $class->any_var(ENGINE) 
            || return $self->error_msg('no_engine');
        class($type)->load;
        return $type;
    }
}


# Constructor method which delegates to the back-end engine.
# So the object returned is, for example, a Template::TT3 object.

sub new {
    my $class = shift;
    $class->engine->new(@_);
}


#-----------------------------------------------------------------------
# Any other class methods are delegated to the protoype engine via the 
# engine_can() method.  This is invoked from an AUTOLOAD handler generated
# by the 'auto_can' feature of Badger::Class.
#-----------------------------------------------------------------------

sub engine_can {
    my ($self, $name) = @_;
    return $self->engine->can($name) && sub {
        shift->prototype->$name(@_);
    };
}

1;

__END__

=head1 NAME

Template3 - Perl interface to the Template Toolkit v3

=head1 SYNOPSIS

    use Template3;
    
    # process() is the all-in-one template processing method with all the
    # bells and whistles.  You can call it as a class method...
    Template3->process($input, $data, $output);
    
    # ...or as an object method
    my $tt3 = Template3->new(%options);
    $tt3->process($input, $data, $output);
    
    # fill() is a lower-level method for processing a template and 
    # returning the generated output
    print $tt3->fill( 
        file => 'example.tt3', 
        data => { name => 'Badger' } 
    );
    
    # template() fetches a template for you to process yourself
    my $template = $tt3->template( 
        text => 'Hello [% name %]' 
    );
    
    print $template->fill( name => 'Badger' );

=head1 PLEASE NOTE

This documentation has been inherited from a previous prototype of TT3 and
hasn't yet been fully edited to reflect the changes to the way the module
works. As a result, some of the documentation may be incomplete and/or
incorrect.

=head1 INTRODUCTION

The B<Template3> module provides a simple interface to the Template Toolkit
for Perl programmers. It is implemented as a thin wrapper or I<facade> around
a L<Template::TT3::Engine> object which is responsible for doing the real work
of processing templates.  The default engine is L<Template::TT3::Engine::TT3>
which implements version 3 of the Template Toolkit language.

The B<Template3> module will eventually replace the current B<Template> module
from TT2.  Until then we must write:

    use Template3;

However, when TT3 is finally released (on Tuesday, some time shortly after
lunch), we will be able to drop the '3' and just use the C<Template> module:

    use Template;               # no '3'

At this point, anyone who is relying on the C<Template> module to work as it
currently does with TT2 will be sorely disappointed.  TT3 has been completely
re-designed and re-built from the ground up and nothing is guaranteed to work
the same (although most things are quite similar).  

However, all is not lost.  The L<Template2> module is a drop-in replacement
for the current TT2 C<Template> module. 

    use Template2;
    
    # instantiate a Template2 object (note the extra '2')
    my $tt2 = Template2->new( INCLUDE_PATH => '/path/to/templates' );

You can also use the C<as> import option to create C<Template> as an alias.
Then you don't need to change any further C<Template> references in your code.

    use Template2 as => 'Template';
    
    # instantiate a Template object (no extra '2')
    my $tt2 = Template->new( INCLUDE_PATH => '/path/to/templates' );

The L<Template2> module is, like L<Template3>, a thin veneer around an 
L<engine|Template::TT3::Engine> object.  They differ only in which engine
they engage: L<Template::TT3::Engine::TT2> or L<Template::TT3::Engine::TT3>,
respectively.

You will be able to continue using C<Template3> after release.  It will 
remain as an alias and/or thin wrapper that will always use the TT3 engine.
In summary, the C<Template> module will default to the latest version of TT
(TT2, TT3, TT4, etc) while L<Template2>, C<Template3> and so on will always
relate to a specific versions.  Furthermore, the C<Template> module (as it
will be known, C<Template3> as it is currently known) provides options that
allow you to unambiguously specify a particular engine (any engine, in fact).  
For example, the following incantation will engage the TT2 engine and create
C<Template> as an alias to it:

    use Template3
        engine => 'TT2',
        as     => 'Template';

While we're talking about module names, it should also be pointed out that the
TT3 implementation is currently located under the C<Template::TT3::*>
namespace. This is a temporary location to avoid any clashes with existing TT2
C<Template::*> modules. When TT3 is released, the majority of the modules will
be moved "up" a namespace to replace and/or augment the current C<Template::*>
modules. For example, L<Template::TT3::Engine::TT3> will eventually become
L<Template::Engine::TT3>. Anything specific to a particular engine or template
dialect will remain in a dedicated sub-namespace, e.g. C<Template::TT2>,
C<Template::TT3>, etc.

=head1 DESCRIPTION

To use the module you must first load it into your Perl program:

    use Template3;

There are a number of options you can specify when loading the module.
See L<LOAD OPTIONS> below for further details.

You can use the module by calling L<Template> class methods directly:

    Template->process($input, $data, $output);

Or by creating a C<Template> object and calling methods against it:

    my $tt3 = Template3->new();
    $tt3->process($input, $data, $output);

The L<METHODS> section below contains details of all the methods available.
See L<CLASS METHODS> following that for further details on how class methods
are delegated to a I<prototype> object.

=head1 METHODS

TODO: list base classes

=head2 new()

Constructor method.  Accepts a list or reference to a hash array of named
parameters.

    # list of named parameters
    my $tt3 = Template3->new( path => $path );
    
    # hash reference of named parameters
    my $tt3 = Template3->new({ path => $path });

See L<CONFIGURATION OPTIONS> for a full list of configuration options.

=head2 process()

NOTE: the parameters for these methods aren't nailed down yet... they still
might end up more like TT2's process($input, $vars, $output)
UPDATE: yes, I think they will... we'll keep process() being the all-in-one
($input, $data, $output) method and provide others (like fill()) for lower
level stuff.

Method to process a template and return the output generated.  Accepts
a list or hash reference of named parameters.  The template will be loaded
from the C<file> specified, or from the source C<text> provided.  Template
variables can be provided using the C<vars> parameter.

    # template file
    print $tt3->process( file => '/path/to/file.tt3', vars => $vars );
    
    # template text
    print $tt3->process( text => "Hello [% name %]", vars => $vars );

Any errors are thrown as exceptions using Perl's C<die>.  You can use
the L<try|Badger::Base/try()> method (inherited from L<Badger::Base>) 
if you want to "downgrade" any exception errors to false values.  The
L<error()|Badger::Base/error()> method can be called to examine the error
raised.

    $tt3->try->process($input, $data, $output)
        || print "FAIL: ", $tt3->error;

The above example is equivalent to:

    eval { 
        $tt3->process($input, $data, $output) 
    };
    if ($@) {
        print "FAIL: ", $tt3->error;
    }

Errors are returned as L<exception|Badger::Exception> objects, but you 
can safely C<print> them to see a summary of the error type and message.

=head2 engine()

Method to get and/or set the runtime engine for the C<Template> module.
See L<TEMPLATE ENGINES> for further details.

=head2 prototype()

Returns the prototype object. This method is inherited from
L<Badger::Protoype>.  See L<CLASS METHODS>.

=head1 CLASS METHODS

When you call a L<Template3> class method it is delegated to a I<prototype>
object for that class.  The prototype object will be automagically created
(by the L<prototype()> method) and cached for subsequent use.

So calling a class method like this:

    Template3->print( file => $file );

is directly equivalent to calling an object method against the class
prototype, like this:
    
    Template3->prototype->print( file => $file );

The L<prototype()> method creates a new object by calling the L<new()>
class method.  It then stores the returned object in the class C<$PROTOTYPE>
variable and returns this cached object on subsequent calls.

Note that you can configure the prototype object by calling the L<config()>
method.

NOTE: this doesn't work yet...

    Template3->config( path => $path );

Or explicitly:
    
    Template3->prototype->config( path => $path );  # same thing as above

The object returned by the L<prototype()> method will be an instance of the
I<engine> class in use (as created by the L<new()> method). The following 
sections describes engines in further detail.

=head1 TEMPLATE ENGINES

The C<Template3> module is implemented as a thin wrapper or I<facade> around a
L<Template::TT3::Engine> object which is responsible for doing the real work of
processing templates. 

The default engine is L<Template::Engine::TT3>, implementing the B<TT3> API
for the Template Toolkit. This is slightly different to the B<TT2> API
(UPDATE: in fact it might not be that different after all).

You can enable a different engine by calling the C<engine> class method. For
example, the use the B<TT2> engine:

    use Template3;
    Template3->engine('Template::TT3::Engine::TT2');

C<TT2> and C<TT3> are provided as aliases for their respective engines.

    use Template3;
    Template3->engine('TT2');

The C<Template3> module will then interface to the
L<Template::TT3::Engine::TT2> engine which provides an API which is backwardly
compatible with B<TT2>.

    # TT2 API
    my $tt = Template3->new( INCLUDE_PATH => '/path/to/templates' );
    $tt->process('example.tt2', { name => 'Badger' });

You can also engage an engine using the C<engine> load option:

    use Template3 engine => 'TT2';

Or for the specific case of B<TT2>, you can write:

    use Template 'TT2';

This is the easiest way to ensure that your existing programs using the
B<TT2> v2 API continue to work with version 3 of the C<Template3> module.

You can also use an engine module directly and bypass the C<Template3>
module altogether.

    use Template::TT3::Engine::TT3;
    
    my $tt3 = Template::TT3::Engine::TT3->new(
        template_path => '/path/to/templates',
    );
    
    $tt3->process('example.tt3', { name => 'Badger' });

You can do the same thing with C<TT2>:

    use Template::TT3::Engine::TT2;
    
    my $tt2 = Template::TT3::Engine::TT2->new( 
        INCLUDE_PATH => '/path/to/templates' 
    );
    
    $tt2->process('example.tt2', { name => 'Badger' });

Although in this particular case, the C<TT2> engine module is little more
than a thin wrapper around L<Template::TT2>, so you might as well use it 
directly.

    use Template::TT2;
    
    my $tt2 = Template::TT2->new( 
        INCLUDE_PATH => '/path/to/templates' 
    );
    
    $tt2->process('example.tt2', { name => 'Badger' });

=head1 LOAD OPTIONS

The following options can be specified when you C<use> the C<Template3> module.

=head2 engine

This allows you to specify the engine module you want to use. The default is 
L<Template::TT3::Engine::TT3>.

    use Template engine => 'Template::TT3::Engine::TT2';

You can drop the C<Template::TT3::Engine> prefix and leave it up to the 
L<Template::TT3::Engines> factory module to find and load the relevant 
module for you.

    use Template engine => 'TT2';

=head2 TT2

Shorthand for engaging the C<TT2> engine and creating a C<TT2> alias.

    use Template 'TT2';
    
    my $tt2 = TT2->new();

=head2 TT3

Shorthand for engaging the C<TT3> engine and creating a C<TT3> alias. 

    use Template 'TT3';
    
    my $tt3 = TT3->new();

=head1 CONFIGURATION OPTIONS

=head2 path / template_path

Specify the location of templates as a single value or a reference to a
list of values.

    my $tt = Template->new( path => '/path/to/templates' );
    my $tt = Template->new( path => [ '/path/one', '/path/two' ] );

NOTE: this isn't implemented yet

=head2 data

Define a default set of data for template variables.

    my $tt = Template->new( vars => {
        name  => 'Badger',
        email => 'badger@template-toolkit.org',
    });

NOTE: this isn't implemented yet

=head2 ...MORE TODO...

=head1 BUGS

The C<Template3> module is mostly functional and correct, but the engines
behind it don't necessarily do what they're supposed to (yet).

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

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



