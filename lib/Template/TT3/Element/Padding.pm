package Template::TT3::Element::Padding;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element::Text',
    view      => 'padding';


1
__END__
    
#-----------------------------------------------------------------------
# Template::TT3::Element::Padding - a thin subclass of the text element
# used to represent sythesised text tokens added as part of the scanning
# process.  For example, the '=' pre and post chomp flags collapse any
# preceding/following text to a single space.  We save the original 
# whitespace (of which there may be none) as a whitespace token and add
# new padding token of a single space.  When we want to re-generate the 
# original template source we print out the whitespace but ignore padding.
# OTOH, when we're parsing we ignore whitespace but include padding as
# kind of text expression.
#-----------------------------------------------------------------------

