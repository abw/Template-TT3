package Template::TT3::Tag::Comment;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag::Closed';


sub scan {
    my ($self, $input, $output, $text, $start, $pos) = @_;
    my ($token, $type);
    
    $self->debug("pre-text: <$text>") if DEBUG && $text;
    $output->text_token($text, $pos)
        if defined $text && length $text;
    
    $self->debug("tag starting: <$start>") if DEBUG && $start;
    $pos  = pos $$input;
    $pos -= length($start);
    
    $$input =~ /$self->{ match_to_end }/cg
        || return $self->error_msg( no_end => $self->{ end } );
        
    $self->debug("matched to end of comment tag: $2") if DEBUG;

    return $output->comment_token($start . $1, $pos);
}
    

1;

