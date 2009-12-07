package Template::TT3::Element::Control::Commands;

use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    constants  => ':elements HASH',
#    as         => 'name_expr',
    as         => 'args_expr',
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
    my $args = $self->[ARGS];
    my @cmds = $args->params( $context->loopback );
    my $cmds;

    return $self->error_msg( cmds_undef => $self->[TOKEN], $args->source )
        unless @cmds;
    
    if (@cmds == 1) {
        $cmds = shift @cmds;
    }
    else {
        $cmds = { map { $_ => $_ } @cmds };
    }

    return $self->error_msg( cmds_undef => $self->[TOKEN], $args->source )
        unless defined $cmds;

    $cmds = {
        $cmds => $cmds
    } unless ref $cmds eq HASH;
    
    $self->debug("Setting CMDS: $cmds") if DEBUG;
    
    my $scanner = $context->scope->scanner
        || return $self->error_msg( no_scanner => $self->[TOKEN] );
    
    my $tag = $scanner->tagset->default_tag
        || return $self->error_msg( no_tag => $self->[TOKEN] );
        
    $tag->commands($cmds);
    
    return ();
}


1;