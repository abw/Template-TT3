# custom tag for scanner controls - can probably move this into T::Tag::Control

package Template::TT3::Tag::Scanner;

use Template::TT3::Class
    base      => 'Template::TT3::Tag::Control',
    version   => 3.00,
    debug     => 0,
    constants => ':elem_slots';


our $COMMANDS = {
    TAGS => \&parse_tags,
};


sub parse {
    my ($self, $token, $scanner) = @_;
    my $last = $token;
    
    while ($token = $token->next_skip_ws) {
        print "** ", $token->text, "\n";
        $last = $token;
    }
    
    # wind forward over any trailing whitespace - FIX ME
    while ($token = $last->next) {
        $last = $token;
    }
    
    return $last;
}


1;