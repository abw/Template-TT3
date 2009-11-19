package Template::TT3::Element::Role::Filename;

use Template::TT3::Class 
    version    => 2.718,
    constants  => ':elements',
    mixins     => 'as_filename filename';


sub as_filename {
    my ($self, $token) = @_;
    my $next;
    
    # advance token
    $$token = $self->[NEXT];

    # our token forms the start of the filename
    $self->[EXPR] = $self->[TOKEN];
    
    # add any subsequent filename tokens onto the filename
    $self->[EXPR] .= $next->[EXPR]
        if $next = $$token->as_filename($token);
    
    # rebless self into a filename token
    $self->become('filename');

    return $self;
}

sub filename {
    $_[SELF]->[EXPR];
}



1;