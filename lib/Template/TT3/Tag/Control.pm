package Template::TT3::Tag::Control;

use Template::TT3::Grammar::TT3;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag::Inline',
    constants => ':elem_slots';


sub tokens {
    my ($self, $input, $output, $scanner) = @_;
    my $first = $output->last;
    my $end   = $self->SUPER::tokens($input, $output, $scanner);
    my $last  = $self->parse($first, $input, $output, $scanner);
    
    # set a forward reference from the first token to the last, so that 
    # we can skip over any control tokens when parsing runtime expressions.
    $self->debug("setting GOTO on $first ($first->[TOKEN]) to $last ($last->[TOKEN])")
        if DEBUG;
        
    $first->[GOTO] = $last;    # skip to last token
    
    return $end;
}


sub parse {
    my ($self, $token, $input, $output, $scanner) = @_;
    my $last = $token;

    while ($token = $token->next_skip_ws) {
        print "** ", $token->text, "\n";
        $last = $token;
    }
    
    $token = $last;
    
    # wind forward over any trailing whitespace - FIX ME
    while ($token && ($token = $token->next)) {
        $last = $token;
        # FIXME: 
#        $token = $last->skip_ws
#            || return $self->error("Unexpected control token: ", $token->token);
    }
    
    return $last;
}



1;

__END__

=head1 NAME

Template::TT3::Tag::Control

=head1 DESCRIPTION

A base class for all tags that embed compile time controls.
