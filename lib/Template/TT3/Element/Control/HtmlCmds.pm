package Template::TT3::Element::Control::HtmlCmds;

use Template::TT3::Element::HTML;
use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    constants  => ':elements',
    as         => 'args_expr',
    utils      => 'tt_args',
    messages   => {
        no_scanner => 'Scanner is not accessible to %s control.',
        no_tag     => 'Tag is not accessible to %s control.',
    },
    constant   => {
        HTML_ELEMENT => 'Template::TT3::Element::HTML',
    },
    alias => {
        text => \&value,
        values => \&value,
    };



sub value {
    my ($self, $context) = @_;
    my $html = $self->HTML_ELEMENT;
    
    # create a local variables stash that contains just the HTML element
    # name that map straight back to the element names
    $context = $context->just( $html->element_name_hash );
    
    # Now evaluate the arguments list in the dummy context.  This allows us
    # to re-use the function parameter mechanism to collect positional 
    # arguments and named parameters.  The mechanism will evaluate variables
    # like 'table', 'ul' and 'li' back to their literal names 'table', 'ul'
    # and 'li' and raise an error if any are undefined.
    my ($named, @posit) = tt_args( $self->[ARGS]->params($context) );

    # create a composite hash of everything we've been asked for
    $named ||= { };
    @$named{ @posit } = @posit
        if @posit;
        
    $self->debug("Loading HTML commands: ", $self->dump_data($named)) if DEBUG;

    my $scanner = $context->scope->scanner
        || return $self->error_msg( no_scanner => $self->[TOKEN] );
    
    my $tag = $scanner->tagset->default_tag
        || return $self->error_msg( no_tag => $self->[TOKEN] );
        
    # FIXME: This isn't hygenic.  Also required a copy of %$named because
    # they're PARAMS and the Badger::Utils self_params() function it uses
    # is only looking out for a HASH.  (FIXME)
    $tag->add_commands( $self->HTML_ELEMENT->commands(%$named) );
    
    return ();
}


1;