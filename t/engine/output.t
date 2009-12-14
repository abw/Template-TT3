#============================================================= -*-perl-*-
#
# t/engine/output.t
#
# Test the various input options.
#
# Run with -h option for help.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger 
    lib => '../../lib',
    Filesystem => 'Bin';

use Template::TT3::Test 
    debug => 'Template::TT3::Hub',
    args  => \@ARGV,
    tests => 19;

use Template3;


#-----------------------------------------------------------------------
# create engine
#-----------------------------------------------------------------------

my $idir = Bin->dir('templates' );
my $odir = Bin->dir('output');

my $tt3  = Template3->new( 
    template_path => $idir,
    output_path   => $odir,
);
ok( $tt3, 'created template engine' );


#-----------------------------------------------------------------------
# output to text string
#-----------------------------------------------------------------------

my $output = '';
my $result = undef;

$result = $tt3->process(
    'women_children.tt3',               
    { when => 'First' }, 
    \$output,
);
ok( $result, "true result: $result" );
is( $output, 'Women and Children First', 'Women and Children First' );


#-----------------------------------------------------------------------
# output to named file
#-----------------------------------------------------------------------

my $outname = 'wc2.tmp';
my $outfile = $odir->file($outname);
$outfile->delete if $outfile->exists;
ok( ! $outfile->exists, 'output file does not exist' );

$result = $tt3->process(
    'women_children.tt3',               
    { when => 'Second' }, 
    $outname,
);

ok( $result, "true result: $result" );
ok( $outfile->exists, 'output file now exists' );
is( $outfile->text, 'Women and Children Second', 'Women and Children Second' );


#-----------------------------------------------------------------------
# output to file object
#-----------------------------------------------------------------------

$outfile->delete if $outfile->exists;
ok( ! $outfile->exists, 'output file has been deleted' );

$result = $tt3->process(
    'women_children.tt3',               
    { when => 'Third' }, 
    $outfile,
);
ok( $result, "true result: $result" );
ok( $outfile->exists, 'output file now exists again' );
is( $outfile->text, 'Women and Children Third', 'Women and Children Third' );


#-----------------------------------------------------------------------
# output to code object
#-----------------------------------------------------------------------

my @output;

$result = $tt3->process(
    'women_children.tt3',               
    { when => 'Fourth' }, 
    sub { push(@output, @_) },
);
ok( $result, "true result: $result" );
is( scalar(@output), 1, 'one output in array from sub' );
is( $output[0], 'Women and Children Fourth', 'Women and Children Fourth' );



#-----------------------------------------------------------------------
# output to array
#-----------------------------------------------------------------------

@output = ();

$result = $tt3->process(
    'women_children.tt3',               
    { when => 'Fifth' }, 
    \@output,
);
ok( $result, "true result: $result" );
is( scalar(@output), 1, 'one output in array' );
is( $output[0], 'Women and Children Fifth', 'Women and Children Fifth' );


#-----------------------------------------------------------------------
# return output
#-----------------------------------------------------------------------
$output = '';
$output = $tt3->process(
    'women_children.tt3',               
    { when => 'Sixth' }, 
);
ok( $output, 'got template output' );
is( $output, 'Women and Children Sixth', $output );



