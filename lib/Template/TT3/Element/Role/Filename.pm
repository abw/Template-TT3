package Template::TT3::Element::Role::Filename;

use Template::TT3::Class 
    version    => 2.69,
    constants  => ':elements',
    mixins     => 'parse_filename filename';


sub parse_filename {
    my ($self, $token) = @_;
    my $next;
    
    # Our token forms the start of the filename
    $self->[EXPR] = $self->[TOKEN];

    # Advance token pointer to the next token
    $$token = $self->[NEXT];

    # Append any subsequent filename elements
    $self->[EXPR] .= $next->[EXPR]
        if $next = $$token->parse_filename($token);

    # Rebless self into a filename element
    $self->become('filename');
    
    return $self;
}


sub filename {
    defined $_[SELF]->[EXPR]
          ? $_[SELF]->[EXPR]
          : $_[SELF]->[TOKEN]
}



1;