package Template3;

use 5.008;
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
    unshift(
        @$symbols, 
        engine => 'TT2', 
        as     => 'TT2', 
    );
}


sub _TT3_hook {
    my ($class, $target, $symbol, $symbols) = @_;
    unshift(
        @$symbols, 
        engine => 'TT3', 
        as     => 'TT3'
    );
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

    # simple all-in-one method to process a template
    Template3->process($input, $data, $output);
    
    # or for fine control
    Template3->render(
        input  => $input,
        data   => $data,
        output => $output,
        # plus any other environment options
    );
    
    # creating a Template3 object
    my $tt3 = Template3->new(
        template_path => '/path/to/templates',
        header        => 'site/header.tt3',
        footer        => 'site/footer.tt3',
    );
    
    # then use it
    $tt3->process('hello.tt3', { name => 'World' });
    
    # or
    $tt3->render(
        input  => 'hello.tt3', 
        data   => { name => 'World' },
        output => 'hello.html',
    );

=head1 PLEASE NOTE

This documentation has been inherited from a previous prototype of TT3 and
hasn't yet been fully edited to reflect the changes to the way the module
works. As a result, some of the documentation may be incomplete and/or
incorrect.

=head1 INTRODUCTION

The B<Template3> module provides a simple interface to the Template Toolkit
for Perl programmers. It is implemented as a thin wrapper around a
L<Template::TT3::Engine> object which is responsible for doing the real work
of processing templates. The default engine is L<Template::TT3::Engine::TT3>
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

For further information about backward compatibility with version 2 of the 
Template Toolkit, please see L<Template::TT3::Manual::Compatibility>.

=head1 DESCRIPTION

To use the module you must first load it into your Perl program:

    use Template3;

There are a number of options you can specify when loading the module.
See L<LOAD OPTIONS> below for further details.

You can use the module by calling L<Template3> class methods directly:

    Template3->process($input, $data, $output);

Or by creating a C<Template3> object and calling methods against it:

    my $tt3 = Template3->new;
    $tt3->process($input, $data, $output);

The L<METHODS> section below contains details of all the methods available.
See L<CLASS METHODS> following that for further details on how class methods
are delegated to a I<prototype> object.

=head1 LOAD OPTIONS

The following options can be specified when you C<use> the C<Template3>
module.

=head2 engine

The C<Template3> module is implemented as a thin wrapper around a
L<Template::TT3::Engine> object which is responsible for doing the real work
of processing templates.

The default engine is L<Template::TT3::Engine::TT3>, implementing the B<TT3>
API for the Template Toolkit. This is slightly different to the B<TT2> API
(UPDATE: in fact it might not be that different after all).

The C<engine> option allows you to specify the engine module that you want to 
use.

    use Template3
        engine => 'Template::TT3::Engine::TT2';

You can drop the C<Template::TT3::Engine> prefix and leave it up to the 
L<Template::TT3::Engines> factory module to find and load the relevant 
module for you.

    use Template3
        engine => 'TT2';

=head2 as

This creates an alias to the C<Template3> module.  For example, if your
existing code expecting to use the L<Template> module then you can create
an alias from L<Template> to L<Template3>.

    use Template3
        as => 'Template';
    
    my $tt3 = Template->new;

=head2 TT2

Shorthand for engaging the C<TT2> engine and creating a C<TT2> alias.

    use Template3 'TT2';
    
    my $tt2 = TT2->new;

It is equivalent to:

    use Template3
        engine => 'TT2',
        as     => 'TT2';

=head2 TT3

Shorthand for engaging the C<TT3> engine and creating a C<TT3> alias. 

    use Template 'TT3';
    
    my $tt3 = TT3->new;

It is equivalent to:

    use Template3
        engine => 'TT3',
        as     => 'TT3';

=head2 TODO

We should have other options for configuring the prototype engine.  e.g.

    use Template3
        template_path => '/path/to/templates',
        dialect       => 'TT3';

Hmmm... that's going to be tricky.  It requires us to know about all the
options that any engine/dialect/service/etc could implement (not feasible)
or to blindly accept any options which is sub-optimal (no way to automatically
detect typos, invalid options, etc).  Probably better to have an explicit
config option.

    use Template3
        config => {
            template_path => '/path/to/templates',
            dialect       => 'TT3',
        };

We could perhaps also allow a config file:

    use Template3
        config => '/path/to/config/file.yaml';  # detect codec from extension

=head1 CONFIGURATION OPTIONS

Please note that the following list is incomplete. This is partly because I
haven't got around to documenting them yet, and partly because there are so
many of them that I haven't decided which ones should go here and which should
be relegated to the longer L<Template::TT3::Manual::Config> documentation.
Furthermore, there are a number of configuration options which should work,
and do work (as far as I'm aware), but don't yet have tests explicitly proving
that they work.  At that point in time I'd rather document the stuff that I
know works and add other items as and when I write the tests for them.

TODO: Explain how TT3 is built from a large number of small, (mostly) simple
components. They all have their own configuration options. The L<Template3>
module is a thin wrapper around L<Template::TT3::Engine::TT3> (or whatever
other engine you explicitly select). The engine creates a
L<Template::TT3::Hub> which acts as the central repository for all the things
we might need.  We pass the entire configuration hash over to the hub and
then leave it up to the hub to create whatever we need (templates providers, 
dialects, context objects, and so on).  The hub ensures that the constructor
for each component gets a copy of the config (or the relevant sub-section 
within it).  So in summary, you can specify any option supported by any
sub-component of TT3 and it should (fingers crossed) get forwarded to the
components's constructor.

TODO: L<Template::TT3::Manual::Config> will eventually contain the full
description of all the options.  This section should contain a summary of 
the most important options.

=head2 dialect

This option allows you to specify the template dialect that you want to use.
At present there is only one dialect: TT3. A TT2 dialect will be provided in
the near future, offering something very similar to the current TT2 language,
but implemented using the new TT3 parser. You can also create your own
dialects, either to customise TT3 or to plug in an entirely different template
language. Until I've had the chance to write more about this, you might like
to consult the slides from my London Perl Workshop talk which shows a trivial
example of creating a custom dialect.
L<http://tt3.template-toolkit.org/talks/tt3-lpw2009/slides/slide17.html>.

    my $tt3 = Template3->new( 
         dialect => 'TT2'           # no TT2 dialect yet - coming RSN
    );

=head2 template_path

This option allows you to specify the location of templates as a single value
or a reference to a list of values.

    # single location
    my $tt3 = Template3->new( 
        template_path => '/path/to/templates' 
    );
    
    # multiple locations
    my $tt3 = Template3->new( 
        template_path => [ '/path/one', '/path/two' ] 
    );

Each item in the path can be a reference to a hash array containing the
path and any other configuration items relating to the templates loaded
from that location.  The following example shows how you can define a 
template path that loads TT2 templates from one location and TT3 templates
from another (note that the TT2 dialect isn't implemented yet, so this is
theoretical - however, the dialect switching does work)

    my $tt3 = Template3->new( 
        template_path => [ 
            {   path    => '/path/to/templates/tt3', 
                dialect => 'TT3',
            },
            {
                path    => '/path/to/templates/tt2',
                dialect => 'TT2',
            }
        ]
    );

If you don't specify a C<template_path> then TT3 will allow you to access
any file on the filesystem.  Templates specified with relative path names
will be resolved relative to the current working directory.

    use Template3;
    
    Template3->process('hello.tt3');        # in current directory
    Template3->process('../hello.tt3');     # in parent directory
    Template3->process('/tmp/hello.tt3');   # absolute path

=head2 header

This option allows you to specify a header template that should be processed
before each main page template. The output from the footer is added to the
start of the main page output. This affects templates processed using the
L<process()> or L<render()> methods().

    my $tt3 = Template3->new( 
        header => 'site/header.tt3',
    );

=head2 footer

This option allows you to specify a footer template that should be processed
after each main page template.  The output from the footer is added to the 
end of the main page output.  This affects templates processed using the
L<process()> or L<render()> methods().

    my $tt3 = Template3->new( 
        header => 'site/header.tt3',
    );

=head2 wrapper

This option allows you to specify a wrapper template that should be used to
enclose the output from the main page template. The wrapper template is
processed, passing the output generated from the main page template as the
C<content> variable. This affects templates processed using the L<process()>
or L<render()> methods().

    my $tt3 = Template3->new( 
        wrapper => 'site/wrapper.tt3',
    );

=head2 service

TT3 uses a new service pipeline architecture for processing templates.
The pipeline is defined as a number of service components, each of which
does one small and simple thing.

The default pipeline is defined as:

    input => header => footer => wrapper => output

The C<input> service deals with fetching and processing the main page 
template.  The L<header>, L<footer> and L<wrapper> components decorate
the output by adding headers, footers and wrappers respectively.  The
C<output> component emits the generated content to a file, file handle, 
object, or simply returns it if no output target has been specified.

Each of these service components has a corresponding option that can be
specified as a configuration option (see L<header>, L<footer> and L<wrapper>)
and/or as an option to the L<render()> method.

    $tt3->render(
        input  => 'example.tt3',
        header => 'site/header.tt3',
        footer => 'site/footer.tt3',
    );

If you want to do something more complicated then you can defined your own
service pipeline.  For example, if you want two different headers, one which
we'll call the C<site_header> and the other, the C<section_header>, then you
can write something like this:

    my $tt3 = Template3->new(
        service        => [
            'header:site_header',               # type:name is sugar for:
            'header:section_header',            # { type=>$type, name=>$name }
            'footer',
        ],
        site_header    => 'site/header.tt3',    # default site header
        footer         => 'site/footer.tt3',    # default site footer
        section_header => '',                   # no default section header
    );

Note that you must specify a defined but false value for any components
that don't have a default template (e.g. C<section_header> in the above
example).  Otherwise the service component will be optimised out of the 
pipeline and you'll be denied from using it later (this optimisation means
that you don't pay any penalty for things like L<header>, L<footer> and 
L<wrapper> if you don't use them).

Note that the C<input> and C<output> service components are added
automatically.  I'm not 100% sure that this is a good idea so it may 
change in the near future.

Now you can call the L<render()> method and configure the environment to 
affect any of the service components.

    $tt3->render(
        input          => 'hello.tt3',
        section_header => 'welcome/header.tt3',
    );

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

=head2 render(\%env)

This method does the same thing as L<process()> but using named parameters.

    $tt3->render(
        input  => 'example.tt3',
        data   => { name => 'World' },
        output => 'example.html',
    );

The named parameters define an I<environment> that is passed to the L<service>
pipeline. In addition to the C<input>, C<data> and C<output> options
corresponding to the positional arguments of the L<process()> method, the 
environment can also contain parameters that affect other components in
the service pipeline.

    $tt3->render(
        input  => 'example.tt3',
        data   => { name => 'World' },
        output => 'example.html',
        header => 'site/header.tt3',
        footer => 'site/footer.tt3',
    );

=head2 fill($type,$name,%env)

This is a low-level method for processing a single template and returning 
the output generated.  The service pipeline is bypassed, so you don't get
any extra headers, footers, output redirection or anything else like that.

    my $output = $tt3->fill( 
        file => 'example.tt3',
        data => { name => 'Badger' },
    );
    
    my $output = $tt3->fill( 
        text => 'Hello [% name %]',
        data => { name => 'Badger' },
    );

The arguments are a little clumsy at present.  They may get changed
in the near future as part of a general cleaned and consistency drive.

=head2 prototype()

Returns the prototype object. This method is inherited from
L<Badger::Protoype>.  See L<CLASS METHODS>.

=head1 CLASS METHODS

When you call a L<Template3> class method it is delegated to a I<prototype>
object for that class.  The prototype object will be automagically created
(by the L<prototype()> method) and cached for subsequent use.

So calling a class method like this:

    Template3->process($file);

is directly equivalent to calling an object method against the class
prototype, like this:
    
    Template3->prototype->process($file);

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



