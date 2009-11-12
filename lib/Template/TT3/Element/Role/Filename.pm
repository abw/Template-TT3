package Template::TT3::Element::Role::Filename;

use Template::TT3::Class 
    version    => 2.718,
    constants  => ':elem_slots :eval_args',
    mixins     => 'as_filename',
    alias      => {
        text   => \&filename,
        value  => \&filename,
        values => \&filename,
    };

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


1;