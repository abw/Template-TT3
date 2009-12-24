#============================================================= -*-perl-*-
#
# t/dialect/pod.t
#
# Test script for the Template::TT3::Dialect::Pod module which implements
# the POD dialect.  This can parse POD documents into a template element
# tree.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use lib '/home/abw/projects/badger/lib';   # abw testing

use Badger 
    lib        => '../../lib lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug   => 'Badger::Pod::Visitor',
#    debug   => 'Template::TT3::Dialect::Pod Template::TT3::Scanner::Pod',
    args    => \@ARGV,
    tests   => 3;

use Template3;

my $pdir = Bin->dir('pod');

my $tt3 = Template3->new(
    template_path => $pdir,
    dialect       => 'pod',
);
ok( $tt3, 'created TT3 engine with POD dialect' );

#my $template = $tt3->template('example1.pod');
#ok( $template, 'got example1.pod template' );

my $template = $tt3->template('test2.pod');
ok( $template, 'got test2.pod template' );

#print $template->tokens->view_debug;

my $tree = $template->tree;
ok( $tree, "got tree: $tree" );

#print "output: ", $template->fill, "\n";

__END__

#-----------------------------------------------------------------------
# test auto-detect via file extension
#-----------------------------------------------------------------------

$tt3 = Template3->new(
    template_path => $pdir,
    extensions    => {                  # TODO: this name is confusing
        pod => { dialect => 'pod' },
    },
);
ok( $tt3, 'created TT3 engine with filename extension mapping' );

$template = $tt3->template('example1.pod');
ok( $template, 'got example1.pod template' );

print $template->tokens->view_debug;

