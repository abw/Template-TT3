#============================================================= -*-perl-*-
#
# t/cache.t
#
# Test the Template::TT3::Cache module.  
#
# Run with the -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib     => '../../lib';

use Template::TT3::Test 
    debug   => 'Template::TT3::Cache',
    args    => \@ARGV,
    tests   => 18;

use Template::TT3::Cache;
use constant CACHE => 'Template::TT3::Cache';


#------------------------------------------------------------------------
# some basic test of get/set methods
#------------------------------------------------------------------------

my $pkg = CACHE;
my $cache = $pkg->new( size => 3 );
ok( $cache, 'created a cache object' );

# add one
ok( $cache->set( pi => 3.14 ), 'set pi' );
is( $cache->get('pi'), 3.14, 'get pi' );
is( $cache->get('pi'), 3.14, 'get pi again' );

# add another
ok( $cache->set( e => 2.71 ), 'set e' );
is( $cache->get('e'), 2.71, 'get e' );
is( $cache->get('e'), 2.71, 'get e again' );

# update 
ok( $cache->set( e => 2.718 ), 'set e more precise' );
is( $cache->get('e'), 2.718, 'get e more precise' );

# add another
ok( $cache->set( a => 'foo' ), 'set a' );

# check we can still get them all
is( $cache->get('pi'), 3.14, 'still got pi' );
is( $cache->get('e'), 2.718, 'still got e' );
is( $cache->get('a'), 'foo', 'still got a' );

# this should push us over the size limit
ok( $cache->set( b => 'bar' ), 'set b' );

# pi should have been discarded
ok( ! defined $cache->get('pi'),'no more pi' );
ok( $cache->declined(), 'cache declined pi' );
is( $cache->error(), "not found in cache: pi", 'cache declined pi error' );

# but e should still be there
is( $cache->get('e'), 2.718, 'still got e though' );

#print STDERR $cache->_slot_report() if $DEBUG;

__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

