package Template::TT3::Scope;

use Template::TT3::Context;
use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    utils       => 'self_params',
    config      => 'scanner input output template source',
    init_method => 'configure',
    accessors   => 'scanner input output tag',
    constants   => 'OFF ON',
    constant    => {
        CONTEXT => 'Template::TT3::Context',
    };


sub new {
    my $class = shift;
    return ref $class
        ? $class->clone(@_)
        : $class->SUPER::new(@_);
}


sub clone {
    my ($self, $params) = self_params(@_);
    my $class = ref $self 
        || return $self->SUPER::new($params);

    return $class->SUPER::new(
        %$self,
        %$params,
        parent => $self,
    );
}


sub block {
    shift->template->block(@_);
}


sub metadata {
    shift->template->metadata(@_);
}


sub template {
    my $self = shift;
    return $self->{ template } 
        ||= $self->parent('template')
        ||  $self->error_msg( missing => 'template' );
}


sub parent {
    my $self   = shift;
    my $parent = $self->{ parent };
    
    # act as a simple accessor when called without arguments
    return $parent unless @_;
 
    # otherwise lookup the named item
    my $item = shift;

    $self->debug("looking up $item in parent") if DEBUG;
 
    # walkup through the parent chain looking for the item
    while ($parent) {
        $parent->{ $item } && return;
        $parent = $parent->{ parent };
    }
}


sub context {
    my $self = shift;

    # Control tags execute expressions at compile time.  Expressions need
    # a context to be executed in.  So we have the current lexical scope
    # create a context on demand that includes variable references to the 
    # scanner (TODO: and various other items).

    # FIXME: we can't cache this context reference without creating a 
    # circular reference.  Either use weaken or do something else.
    return $self->CONTEXT->new(
        scope => $self,
        data  => {
            %$self,
            
            # FIXME: these are required for "TAGS off" but they
            # should probably be constant keywords defined in the
            # grammar.
            off     => OFF,
            on      => ON,
        },
   );


    # older code
    return $self->{ context } 
       ||= $self->CONTEXT->new(
                scanner   => $self->{ scanner },
                variables => {
                    scanner => $self->{ scanner },
                    # FIXME: these are required for "TAGS off" but they
                    # should probably be constant keywords defined in the
                    # grammar.
                    off     => OFF,
                    on      => ON,
                },
           );
           
}


1;
