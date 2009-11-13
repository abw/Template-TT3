#============================================================= -*-perl-*-
#
# t/module/tagset.t
#
# Test the Template::TT3::Tagset module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';
use Template::TT3::Test 
    tests => 1,
    debug => 'Template::TT3::Tagset',
    args  => \@ARGV;

use Template::TT3::Tagset::TT3;
use constant TAGSET => 'Template::TT3::Tagset::TT3';

my $tagset = TAGSET->new();
ok( $tagset, "created tagset: $tagset" );


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
