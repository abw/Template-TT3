package Template::TT3::Tag::Comment;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag::Inline';


sub tokens {
    my ($self, $input, $output) = @_;
    my $pos = pos $$input;
    
    $$input =~ /$self->{ match_to_end }/cg
        || return $self->error_msg( no_end => $self->{ end } );
        
    $self->debug("matched to end of comment tag: $2") if DEBUG;

    $output->comment_token($1, $pos);

    return $2;
}
    

1;

