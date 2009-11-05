package Template::TT3::Tag::Control;

use Template::TT3::Class
    base      => 'Template::TT3::Tag',
    version   => 3.00,
    debug     => 0,
    constants => ':elem_slots';
    constant  => {
        SCANNER_ARG => 5
    };


sub tokens {
    my $self  = shift;
    # remaining args are: ($input, $output, $text, $start, $pos, $scanner)
    my $first = $self->SUPER::tokens(@_);
    my $last  = $self->parse($first, $_[SCANNER_ARG]);
    
    # set a forward reference from the first token to the last, so that 
    # we can skip over any control tokens when parsing runtime expressions.
    $first->[GOTO] = $last;    # skip to last token
    
    return $last;
}

sub parse {
    shift->not_implemented('in base class');
}


1;

__END__

=head1 NAME

Template::TT3::Tag::Control

=head1 DESCRIPTION

A base class for all tags that embed compile time controls.
