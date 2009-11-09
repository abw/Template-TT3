package Template::TT3::Test;

use Badger::Test ':default manager';           # to import ok(), is(), etc.
use Template::TT3::Class
    version   => 0.01,
    base      => 'Badger::Test',
    debug     => 0,
    utils     => 'params',
    constants => 'HASH CODE',
    exports   => {
        all   => 'test_expect',
        any   => 'data_text data_tests callsign test_expressions',
    };

use Template::TT3::Template;

our $MAGIC    = '\s* -- \s*';
our $ENGINE   = 'Template::TT3';
our $HANDLER  = \&test_handler;
our $TEMPLATE = 'Template::TT3::Template';
our $DATA;


sub test_expect {
    my $config  = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $tests   = $config->{ tests   } || data_tests();
    my $handler = $config->{ handler } || $HANDLER;
    my $guard;

    foreach my $test (@$tests) {
        # handle -- skip -- flag
        if (grep(/skip/, @{ $test->{ inflags } })) {
            my $msg = $test->{ inflag }->{ skip };
            $msg = $msg eq '1' ? '' : " ($msg)";
            skip_some(1, "$test->{ name }$msg");
            next;
        }
        
        # handle -- only something -- flag
        if ( ($guard = $test->{ inflag }->{ only })  
        && ! $config->{ vars }->{ $guard } ) {
            skip_some(1, "$test->{ name } (only for $guard)");
            next;
        }

        if ($config->{ step }) {
            print STDERR "\n# ready to run: $test->{ name }   (press ENTER)";
            my $ans = <STDIN>;
            chomp $ans;
            exit if ($ans eq 'q');
        };

        my $result = &$handler($test, $config);
        chomp $result;

        if ($result eq $test->{ expect }) {
            ok(1, $test->{ name });
        }
        else {
            # pass it over to is() to make pretty 
            is( $result, $test->{ expect }, $test->{ name });
        }
    }
}


sub test_handler {
    my ($test, $config) = @_;
    my $engine = $config->{ engine }
        ||= $ENGINE->new($config->{ config } || { });

    if (my $use = $test->{ inflag }->{ use }) {
        $engine = $config->{ engine } = $config->{ engines }->{ $use }
            || die "Invalid engine specified: $use\nEngines available: ", 
                    join(', ', keys %{ $config->{ engines } || { } }), 
                    "\n";
    }
    my $in  = $test->{ input };
    my $out = '';
    
    $engine->process(\$in, $config->{ vars }, \$out);

    if ($test->{ exflag }->{ process }) {
        my ($expin, $expout);
        $expin = $test->{ expect };
        $engine->process(\$expin, $config->{ vars }, \$expout);
        $test->{ expect } = $expout;
    }

    return trim $out;
}


sub data_text {
    return $DATA if defined $DATA;
    local $/ = undef;
    no warnings;
    $DATA = <main::DATA>;
    $DATA =~ s/^__END__.*//sm;
    return $DATA;
}


sub data_tests {
    my $source = shift || data_text();
    my (@tests, $test, $input, $expect);
    my $count = 0;

    # remove any comment lines
    $source =~ s/^#.*?\n//gm;

    # remove the leading backslash from any escaped comments,
    # e.g. \# this comment really should be in the input/output
    $source =~ s/^\\#/#/gm;

    # remove anything before '-- start --' and/or after '-- stop --'
    $source =~ s/ .*? ^ $MAGIC start $MAGIC \n //smix;
    $source =~ s/ ^ $MAGIC stop  $MAGIC \n .* //smix;

    @tests = split(/ ^ $MAGIC test /mix, $source);

    # if the first line of the file was '-- test --' (optional) then the 
    # first test will be empty and can be discarded
    shift(@tests) if $tests[0] =~ /^\s*$/;

    foreach $test (@tests) {
        $test =~ s/ ^ \s* (.*?) $MAGIC \n //x;
        my $name = $1 || 'test ' . ++$count;
        
        # split input by a line like "-- expect --"
        ($input, $expect) = 
            split(/ ^ $MAGIC expect $MAGIC \n/mix, $test);
        $expect = '' 
            unless defined $expect;
        
        my (@inflags, $inflag, @exflags, $exflag, $param, $value);
        while ($input =~ s/ ^ $MAGIC (.*?) $MAGIC \n //mx) {
            $param = $1;
            $value = ($param =~ s/^(\w+)\s+(.+)$/$1/) ? $2 : 1;
            push(@inflags, $param);
            $inflag->{ $param } = $value;
        }

        while ($expect =~ s/ ^ $MAGIC (.*?) $MAGIC \n //mx) {
            $param = $1;
            $value = ($param =~ s/^(\w+)\s+(.+)$/$1/) ? $2 : 1;
            push(@exflags, $param);
            $exflag->{ $param } = $value;
        }
            
        for ($input, $expect) {
            s/^\s+//;
            s/\s+$//;
        }

        $test = {
            name    => $name,
            input   => $input,
            expect  => $expect,
            inflags => \@inflags,
            inflag  => $inflag,
            exflags => \@exflags,
            exflag  => $exflag,
        };
    }

    return wantarray ? @tests : \@tests;
}


sub callsign {
    return {
        map { substr($_, 0, 1) => $_ }
        qw( 
            alpha bravo charlie delta echo foxtrot golf hotel india 
            juliet kilo lima mike november oscar papa quebec romeo 
            sierra tango umbrella victor whisky x-ray yankee zulu 
        )
    }
}


sub test_expressions {
    my $config   = params(@_);
    my $tclass   = $config->{ template  } || $TEMPLATE;
    my $vars     = $config->{ variables };
    my $mkvars   = ref $vars eq CODE ? $vars : sub { $vars };
    my $debug    = $config->{ debug } || 0;

    my $block_mode = defined $config->{ block_mode } 
        ? $config->{ block_mode } 
        : 0;
    
    $config->{ handler } = sub {
        my $test   = shift;
        my $output = '';
        my @lines;
        
        local $DEBUG = $test->{ inflag }->{ debug } ? 1 : $debug;

        # -- block -- flag indicates one single test, otherwise we 
        # split the block into separate lines and feed them to the
        # parser/generator one by one.  $block_mode can also be set
        if ($block_mode || $test->{ inflag }->{ block }) {
            @lines = $test->{ input };
        }
        else {
            @lines  = split(/\n/, $test->{ input });
        }
        
        if ($test->{ exflag }->{ collapse }) {
            # collapse any whitespace in expected output
            $test->{ expect } =~ s/\n\s*//sg;
        }

        foreach my $line (@lines) {
            my $result = eval {
                manager->debug(' INPUT: ', $line) if $DEBUG;
                my $template = $tclass->new( text => '[% ' . $line . ' %]' );
                manager->debug("TOKENS:\n", $template->tokens->sexpr) 
                    if $config->{ dump_tokens }; #$DEBUG;
                $template->fill( $mkvars->() );
            };
            if ($@) {
                my $error = ref($@) ? $@->info : $@;
                manager->debug(' ERROR: ', $error) if $DEBUG;
                $result = "<ERROR:$error>";
            }
            elsif ($DEBUG) {
                manager->debug('OUTPUT: ', $result);
            }

            $output .= "$result\n";
        }
        chomp $output;
        return $output;
    };

    test_expect($config);
}


1;
__END__

=head1 NAME

Template::TT3::Test - useful functions for writing test scripts

=head1 SYNOPSIS

    use Template::TT3::Test 
        tests  => 8, 
        debug  => 'Template::TT3::Context',
        args   => \@ARGV;
        
    # use default configuration...
    test_expect();
    
    # ...or custom config and/or vars
    test_expect(
        config => {
            # TT3 config
        },
        vars => {
            # TT vars
        }
    );
    
    # ...or multiple engines
    test_expect(
        engines => {
            engine1 => {
                # TT3 config for engine 1
            },
            engine2 => {
                # TT3 config for engine 2
            },
        },
    );
    
    __DATA__
    # this is a comment
    
    -- test This is the first test
    Hello [% name or 'World' %]
    -- expect --
    Hello World
    
    -- test This is the second test --
    # use another engine configuration
    -- use engine1 --
    Hello

=head1 DESCRIPTION

This module implements a number of useful subroutines for testing the Template
Toolkit. It is a subclass of L<Badger::Test> which performs the same basic
function as the L<Test::Simple> and L<Test::More> modules. It also adds some
methods specific to the Template Toolkit.

=head1 EXPORTED SUBROUTINES

The following subroutine is exported by default, in addition to those 
exported by the L<Badger::Test> base class.

=head2 test_expect(\%params)

This subroutine can be used to run a number of template-based tests defined in
the data section of a program (i.e. following a C<__DATA__> or C<__END__>
line).

    use Template::TT3::Test 
        tests => 1;
        
    test_expect(
        vars => {
            input => 'expected output'
        }
    );
    
    __END__
    -- test Number One --
    This is the [% input %]
    -- expect --
    This is the expected output

The subroutine accepts any of the following parameters

=head3 vars

A reference to a hash array of template variables.

=head3 config

A reference to a hash array of L<Template> configuration parameters which
will be used to create a template engine for processing the source templates
in the tests.

=head3 engine

A reference to a L<Template> engine which will be used to process the source
templates in the tests.

=head3 engines

A reference to a hash array of name L<Template> engines.  These can be 
selected for a particular test using the L<-- use engine_name --|use>
test directive.

=head3 handler

A reference to a subroutine responsible for running each tests.  This 
defaults to the L<test_handler()> subroutine.

=head3 tests

A reference to a list of tests.  This defaults to the tests returned by
the L<data_tests()> subroutine.

=head3 step

When set to a true value this will cause the test handler to pause before
each test and prompt the user to hit RETURN.

=head1 EXPORTABLE SUBROUTINES

The following subroutine are exported on demand, in addition to those 
exported by the L<Badger::Test> base class.

=head2 data_text()

Returns the text from the C<DATA> section of the calling program, coming
after an C<__END__> or C<__DATA__> marker.  If a second C<__END__>
marker is found in the text then it and anything after it is removed.

    use Template::TT3::Test 'data_text'

    print data_text();  # hello world

    __DATA__
    hello world
    __END__
    This part is ignored.  We can put any editor variables/flags here

    # Local Variables:
    # mode: perl
    # perl-indent-level: 4
    # indent-tabs-mode: nil
    # End:
    #
    # vim: expandtab shiftwidth=4:

The text is cached internally so that you can call C<data_text()> as many
times as you like and get the same text back each time.

=head2 data_tests()

Calls L<data_text()> to read the text from the DATA section and then 
splits it into a number of tests.  

The subroutine looks for special command lines embedded in the text,
appearing at the start of a line and surrounded by C<--> character
sequences.  For example:

    this is ignored
    -- start --

    -- test number one --
    This is the input
    -- expect --
    This is the expected output

    -- end --
    this is ignored

Anything coming before a C<-- start --> line or after an C<-- end --> line
is ignored.  Each test begins with a C<-- test --> line which can also 
contain a short name for the test, e.g. C<-- test number one -->.  This is
followed by an C<-- expect --> line and the expected output of the test.

    -- test number one --
    This is the input
    -- expect --
    This is the expected output
    
    -- test number two --
    This is the input for test number two
    -- expect --
    This is the expected output of test two

Each 'test' or 'expect' section can be followed any further flags, also
defined in the same way.  The C<-- skip --> flag can be set, for example,
to temporarily skip a test.

    -- test number one --
    -- skip --
    This is the input
    -- expect --
    This is the expected output

=head2 callsign()

Returns a reference to a hash array mapping letters of the alphabet to their
corresponding words in the phonetic alphabet.

    print callsign->{a};        # alpha

=head1 INTERNAL SUBROUTINES

=head2 test_handler() 

This subroutine is the default test handler used by L<test_expect()>.

=head1 TEST DIRECTIVES

=head2 test

Used to mark the start of a new test.  An option test name may follow.

    -- test --
    input text...
    ...
    
    -- test hello world --
    input text...
    ...

=head2 expect

Used to mark the start of the expected output for a test.

    -- test hello world --
    Hello [% name or 'World' %]
    -- expect --
    Hello World

=head2 skip

Used to skip over a test.  Should appear after the opening L<test>
directive.

    -- test hello world --
    -- skip --
    Hello [% name or 'World' %]
    -- expect --
    Hello World

=head2 only

Used to conditionally run a test if a variable is set to a true value.
For example, if a test depends on C<Some::Random::Module> being available
then you can set the C<has_srm> variable to C<0> or C<1>.

    eval "use Some::Random::Module";
    $HAS_SRM = $@ ? 0 : 1;
    
    test_expect(
        vars => {
            has_srm => $HAS_SRM,
        }
    );

Then your tests can use the <only has_srm> guard clause:

    -- test Some::Random::Module --
    -- only has_srm --
    Test input
    -- expect --
    Test output

=head2 process

This can be added after the L<expect> directive to indicate that the expected
output should be template-processed before comparing it to the output
generated from the test input. This can be used to expand values in the output
that depend on certain conditions. For example, if the output generated from
the test input depends on a language variable, then we can pre-process the
expected output to insert the correct warning message.

    -- test Example test --
    [% warning_message %]
    -- expect --
    -- process --
    [% IF lang =='en' -%]
    DANGER!  DANGER!
    [% ELSIF lang == 'de' -%]
    ACHTUNG!  ACHTUNG!
    [% END %]

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2008 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

