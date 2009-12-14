package Template::TT3::Services;

use Template::TT3::Factory::Class
    version     => 2.71,
    debug       => 0,
    item        => 'service',
    path        => 'Template(X)::(TT3::|)Service',
    constants   => 'HASH ARRAY',
    utils       => 'is_object',
    messages    => {
        no_config => 'No configuration value specified for %s service.',
    };

use Template::TT3::Class
    modules     => 'SERVICE_MODULE';


sub init {
    my ($self, $config) = @_;
    $self->init_hub($config)
         ->init_factory($config);
}


sub type_args {
    my $self = shift;
    my $type = shift;
    my $args = @_ == 1
             ? (ref $_[0] eq HASH ? shift : { template => shift })
             : { @_ };

    # In the usual case the service type and name are synonymous.  e.g. a
    # service C< header => 'foo' > has both type (which determines the module
    # that gets loaded) and name (which indicates the runtime environment
    # parameter that it uses) set to 'header'.  However, we may want to 
    # give different names to services, e.g. 'section_header' instead of 
    # (or as well as 'header').  In this case the service must be specified
    # as a hash ref containing a 'type', e.g. 
    #    site_header => { type => 'header', template => 'site/header' }
    # So we copy the name (site_header) into the hash, and use the type
    # specified in the hash (if any) in preference to the name for locating
    # the service module that we want to use.
    $args->{ name } ||= $type;
    $type = $args->{ type } || $type;
    
    # add a reference back to the services factory in case service components
    # need to access other services or get to the hub
    $args->{ services } = $self;
    
    return ($type, $args);
}


sub connect {
    my $self = shift;
    my ($pipe, $name, $config);
    
    while (@_) {
        $name = shift;
        
        if (is_object(SERVICE_MODULE, $name)) {
            $self->debug("connecting to existing service: $name") if DEBUG;
            $pipe = $name->connect($pipe);
        }
        elsif (ref $name eq ARRAY) {
            $self->debug("connecting to new service: ", $self->dump_data($name)) if DEBUG;
            $pipe = $self->service( @$name )->connect($pipe);
        }
        elsif (ref $name) {
            # TODO: handle the case when we've got a pipeline sub passed in.
            # If it's the first item (i.e. $pipe is undef) then we can set
            # $pipe to it, but if it's not first then we should probably 
            # throw an error because it will be detached from the previous
            # segments.  Or we create a new 'action' service that is a simple
            # wrapper around a code sub that we can bind to previous segment.  
            # But then we can't tell regular code subs from pipeline subs
            # so we would need to treat them all equally.
            return $self->todo('services from refs');
        }
        elsif (@_) {
            $self->debug("connecting to new service: $name => $_[0]") if DEBUG;
            $pipe = $self->service( $name => shift )->connect($pipe);
        }
        else {
            return $self->error_msg( no_config => $name );
        }
    }
    
    return $pipe;
}
        

1;

__END__

=head1 NAME

Template::TT3::Services - factory module for loading template services

=head1 SYNOPSIS

    use Template3;
    use Template::TT3::Services;
    
    # Create a services factory object
    my $services = Template::TT3::Services->new;
    
    # Create some service components
    my $input   = $services->service('input');
    my $header  = $services->service( header  => 'site/header.tt3'  );
    my $footer  = $services->service( footer  => 'site/footer.tt3'  );
    my $wrapper = $services->service( wrapper => 'site/wrapper.tt3' );
    my $output  = $services->service('output');
    
    # Now construct a service pipeline starting with an input...
    my $pipeline = $input->connect;
    
    # ...followed by each of the service components...
    $pipeline = $header->connect($pipeline);
    $pipeline = $footer->connect($pipeline);
    $pipeline = $wrapper->connect($pipeline);
    
    # ...and ending with an output
    $pipeline = $output->connect($pipeline);
    
    # or do it the all-in-one way
    my $pipeline = $services->connect(
        input   => '',
        header  => 'site/header.tt3',
        footer  => 'site/footer.tt3',
        wrapper => 'site/wrapper.tt3',
        output  => ''
    );
    
    # We need a runtime context with some (random) data parameters
    my $context = Template3->context->with( 
        x => 10, 
        y => 20,
    );
    
    # Then we can run the service and it all Just Works[tm]
    print $pipeline->(
        context => $context,
        input   => 'example.tt3',
    );
    
    # Change the environment to affect components in the pipeline
    $pipeline->(
        context => $context,
        input   => 'another.tt3',
        header  => 'my/header.tt3',
        footer  => 'your/footer.tt3',
        wrapper => 'another/wrapper.tt3',
        output  => 'another.html',
    };

=head1 INTRODUCTION

This module is a subclass of L<Template::TT3::Factory> for locating, loading
and instantiating template service modules. 

Service modules are small pipeline components that perform simple tasks to
modify or augment the output generated by processing a template. The most
common application of services is for automatically adding headers, footers
and page wrappers. However, they can also be used to inject various other
processing actions into a service pipeline. For example, a service could be
used to catch and handle processing errors, or to time how long a template
takes to process.

Furthermore, services may modify the runtime environment that affects how 
other services perform.  So you can write a service that automagically
changes which header, footer, wrapper or layout template is used by the 
relevant services that follow it.

All of this is usually handled for you by the L<Template::TT3::Engine::TT3>
module that sits behind the L<Template3> module. Consider the following
example:

    my $tt3 = Template3->new(
        header => 'site/header.tt3',
        footer => 'site/footer.tt3',
    );

Behind the scenes, a service pipeline is constructed that processes whatever
template you specify and then automatically adds the C<site/header.tt3> and
C<site/footer.tt3> header and footer templates respectively.  

If this kind of thing is all you ever need to do then you can stop reading
now. If, however, your needs are more demanding and you find yourself wanting
to add several different headers, change the layout templates dynamically, or
perhaps add some debugging, timing, or logging code to your template
processing service then read on.  This documentation explains how service
components are created and connected into service pipelines, and demonstrates
how you can create your own custom template processing services.

=head1 DESCRIPTION

The C<Template::TT3::Services> module provides the L<service()> method for
loading and instantiating service object. It looks for service modules in the
following places:

    Template::TT3::Service
    Template::Service
    TemplateX::TT3::Service
    TemplateX::Service

For example, requesting a C<header> service returns a
L<Template::TT3::Service::Header> object.

    my $service = Template::TT3::Services->service(
        header => 'site/header.tt3'
    );

You can call it as a class method, as shown in the example above, or as an 
object method.

    my $services = Template::TT3::Services->new;
    my $service  = $services->service(
        header => 'site/header.tt3'
    );

Services can be connected together in a pipeline. In the usual case a pipeline
will start with an L<input|Template::TT3::Service::Input> service. This uses
the C<input> parameter defined in the environment to find, fetch and fill the
main page template.  So we create an input service:

    my $input = $services->service('input');

Then we call the L<connect()|Template::TT3::Service/connect()> method to turn
a service into a pipeline function.

    my $pipeline = $input->connect;

We can now call the pipeline function. We must pass it an environment as a set
of named parameters. The should include a L<context|Template::TT3::Context>
object in which our variable data is defined, and an C<input> parameter 
indicating the template that we want to be processed.

    use Template::TT3::Context;
    
    my $context = Template::TT3::Context->new(
        data => {
            name => 'World',
        }
    );
    
    print $pipeline->(
        input   => 'example.tt3',
        context => $context,
    );

The pipeline function invokes the input service which fetches the C<input>
template (C<example.tt3>) from the context and processes it.  The output
generated by the template is returned.

If we want to automatically add a header to each template then we can
create a header service and connect it to our existing pipeline.  This 
returns a new pipeline function which includes both the input and header
components.

    $header   = $services->service( header => 'site/header.tt3' );
    $pipeline = $header->connect($pipeline);

Now when we run the pipeline we get the main page content plus the header

    print $pipeline->(
        input   => 'example.tt3',
        context => $context,
    );

Want a footer too?  No problem.  We can squish the service creation and 
connection into a single expression as shown below.  It looks slightly
different but it's functionally equivalent to the previous example.

    $pipeline = $services
        ->service( footer => 'site/footer.tt3' )
        ->connect( $pipeline );

The C<Template::TT3::Services> module also defines the L<connect()> method
which combines both actions into one method call.  It creates a service 
component and connects it to the current pipeline.

    $pipeline = $services->connect( 
        $pipeline,
        footer => 'site/footer.tt3',
    );

In fact, you can use L<connect()> to create a number of services and have them
all connected together in order. The only condition is that each service
component is specified as either a pair of (C<$name>, C<$config>) or a
reference of some kind (e.g. an existing service object). That requires us to
define a dummy configuration parameter for the C<input> service which doesn't
usually expect any configuration.

    $pipeline = $services->connect( 
        input  => '',
        header => 'site/header.tt3',
        footer => 'site/footer.tt3',
    );

=head1 CONFIGURATION ITEMS

The module inherits all of the generic configuration options provided by
the L<Template::TT3::Factory> and L<Badger::Factory> base classes.  The
following options are specific to this service factory.

=head2 service_path

This option allows you to add elements to the search path used to locate
service modules.  A single item can be specified as a string.  Multiple
items can be specified by reference to a list.

    my $services = Template::TT3::Services->new(
        service_path => ['My::Service', 'Your::Service'],
    );

=head2 services

This option allows you to specify additional service components by name.
This is typically used to define services that exists outside of the usual
L<service_path> path, or perhaps have unusual capitalisations that the 
default name translation process will fail to resolve.

    my $services = Template::TT3::Services->new(
        services => {
            load_yaml => 'My::Service::LoadYAML',       # vs LoadYaml
        }
    );

=head1 METHODS

This module inherits all methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory> and L<Badger::Base> base classes.
The following methods are also defined or are automatically provided by the
L<Badger::Factory> base class.

=head2 service($type,@args)

Locates, loads and instantiates a service module.  This is created as an 
alias to the L<item()|Badger::Factory/item()> method in L<Badger::Factory>.

    my $service = $services->service( header => 'site/header.tt3' );

The first argument should be a name identifying the service component.
This will automatically be L<camel cased|Badger::Utils/camel_case()> and 
appended to each of the package names in the L<service_path> until a 
matching module can be found and loaded.  For example a type of C<header> 
is mapped to the L<Template:TT3::Service::Header> module.

=head2 services()

Method for inspecting or modifying the services that the factory module 
manages.  This is created as an alias to the L<items()|Badger::Factory/items()> 
method in L<Badger::Factory>.

=head2 connect(@services)

This method of convenience will create a number of services and automatically
connect them together into a service pipeline.

    my $pipeline = $services->connect( 
        input  => '',
        header => 'site/header.tt3',
        footer => 'site/footer.tt3',
    );

=head1 INTERNAL METHODS

=head2 type_args(@args)

This method replaces the default L<type_args()|Badger::Factory/type_args()>
method inherited from the L<Badger::Factory> base class. The first argument is
expected to be a service type that the factory can map to a module name,
e.g. C<header> which is mapped to L<Template::TT3::Service::Header>. If a
single non-hash reference argument follows then it is assume to be a template
name or some other reference from which a template can be constructed.

The end result is that you can write this:

    $service = $services->service( 
        header => 'example.tt3' 
    );

as a convenient shorthand for:

    $service = $services->service( 
        header => {
            template => 'example.tt3' 
        },
    );

=head1 PACKAGE VARIABLES

This module defines the following package variables.  These are declarations
that are used by the L<Badger::Factory> base class.

=head2 $ITEM

This is the name of the item that the factory module returns, and implicitly 
the name of the method by which .  In this case it is defined as C<service>.

=head2 $PATH

This defines the module search path for the factory.  In this case it is 
defined as a list of the following values;

    Template::TT3::Service
    Template::Service
    TemplateX::TT3::Service
    TemplateX::Service

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Template::TT3::Factory>,
L<Template::TT3::Base>, L<Badger::Factory>, and L<Badger::Base> base classes.

It loads modules and instantiates object that are subclasses of
L<Template::TT3::Service>. See L<Template::TT3::Service::Header>,
L<Template::TT3::Service::Footer> and the various other examples of 
specific service modules.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
