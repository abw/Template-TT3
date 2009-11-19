package Template::TT3::Element::Control::Commands;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Command',
    constants  => ':elements',
    as         => 'name_expr',
    alias      => {
        text   => \&value,
        values => \&value,
    },
    messages   => {
        cmds_undef => 'Undefined value returned by %s expression: %s',
        no_scanner => 'Scanner is not accessible to %s control.',
        no_tag     => 'Tag is not accessible to %s control.',
    };


sub value {
    my ($self, $context) = @_;
    my $expr = $self->[EXPR];
    my $cmds = $expr->value($context);
    
    return $self->error_msg( cmds_undef => $self->[TOKEN], $expr->source )
        unless defined $cmds;

    $self->debug("Setting CMDS: $cmds") if DEBUG;
    
    my $scanner = $context->scope->scanner
        || return $self->error_msg( no_scanner => $self->[TOKEN] );
    
    my $tag = $scanner->tagset->default_tag
        || return $self->error_msg( no_tag => $self->[TOKEN] );
        
    $tag->commands($cmds);
    
    return ();
}


1;