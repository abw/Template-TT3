package Template::TT3::Element::Control::Meta;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    constants  => ':elements HASH',
    as         => 'args_expr',
    alias      => {
        text   => \&value,
        values => \&value,
    },
    messages   => {
        no_meta  => 'No metadata defined in %s expression: %s',
        bad_meta => 'Invalid metadata defined in %s expression: %s',
    };


sub value {
    my ($self, $context) = @_;
    
    # evaluate the args to create the metadata
    my $args = $self->[ARGS];
    my @meta = $args->params($context);
    my $meta;

    return $self->error_msg( no_meta => $self->[TOKEN], $args->source )
        unless @meta;
    
    $self->debug("META: ", $self->dump_data(\@meta)) if DEBUG;
    
    # evaluated metadata can be a list of named params, e.g. (title, 'hello') 
    # or a hash reference, e.g. { title => 'hello' }
    $meta = (@meta == 1)
        ? shift @meta
        : { @meta };
    
    return $self->error_msg( bad_meta => $self->[TOKEN], $args->source )
        unless ref $meta eq HASH;
        
    # Ask the scope to find the template to add the metadata.  We <3 Demeter.
    $context->scope->metadata($meta);
    
    return ();
}


1;