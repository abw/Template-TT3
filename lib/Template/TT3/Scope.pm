package Template::TT3::Scope;

use Template::TT3::Context;
use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Base',
    config      => 'scanner',
    init_method => 'configure',
    accessors   => 'scanner',
    constant    => {
        CONTEXT => 'Template::TT3::Context',
    };


sub context {
    my $self = shift;

    # Control tags execute expressions at compile time.  Expressions need
    # a context to be executed in.  So we have the current lexical scope
    # create a context on demand that includes variable references to the 
    # scanner (TODO: and various other items).

    return $self->{ context } 
       ||= $self->CONTEXT->new(
                scanner   => $self->{ scanner },
                variables => {
                    # FIXME: do we need both scanner refs?
                    scanner => $self->{ scanner },
                    # FIXME: these are required for "TAGS off" but they
                    # should probably be constant keywords defined in the
                    # grammar.
                    off     => 'off',
                    on      => 'on',
                },
           );
           
}


1;
