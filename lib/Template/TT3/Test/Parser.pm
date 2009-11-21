package Template::TT3::Test::Parser;
die __PACKAGE__, " is deprecated - use Template::TT3::Test instead\n";


use Template::TT3::Test 'test_expect';
use Template::TT3::Class
    version  => 3.00,
    base     => 'Template::TT3::Test',
    utils    => 'params',
    import   => 'class',
    constant => {
        TAG    => 'Template::TT3::Tag::Inline',
        TOKENS => 'Template::TT3::Tokens',
    },
    exports  => {
        any  => 'test_parser',
    };



sub test_parser {
    my $config = params(@_);

    class(TAG)->load;
    class(TOKENS)->load;

    my $block_mode = defined $config->{ block_mode } 
        ? $config->{ block_mode } 
        : 0;

    $config->{ handler } = sub {
        my $test = shift;
        my $output = '';
        my @lines;

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
                my $tokens = TOKENS->new;
                my $tag    = TAG->new;
                my $text = $line;
                $tag->tokenise(\$text, $tokens);
                $tokens->eof_token();
                $tokens->finish;

                # parse into expression
                my $token  = $tokens->first;
                my $block  = $token->parse_exprs(\$token);
                my $remain = $token->remaining_text;
                
                if ($remain) {
                    die "unparsed tokens: $remain";
                }
                join("\n", map { $_->sexpr } $block->exprs);
            };
            if ($@) {
                my $error = ref($@) ? $@->info : $@;
                $result = "<ERROR:$error>";
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

Template::Test::Parser - additional functions for testing the parser

=head1 SYNOPSIS

    use Template::Test::Parser qw( :all );

=head1 DESCRIPTION

This is a aubclass of Template::TT3::Test with some extra methods for testing 
the Template::TT3::Parser module.

TODO: this documentation needs writing.

=head1 SUBROUTINES

=head2 test_parser()

NOTE: these docs are cut-n-pasted from a previous version and are out of date.

Method to test the parser by feeding each test in the __DATA__ section
into the parse_expression() method (or a method defined in a 
'parse_method' option or set in a test in a -- parse_method_name -- 
flag) called against a parser object passed in the 'parser' option
or defaulting to a Template::Parser object.  Then feeds the output
into a generator (the 'generator' option) which defaults to 
Template::Generator::Debug, and can also be controlled by a test flag
such as -- generate_perl -- to invoke the 'perl' generator in the 
generators test set, passed as the 'generators' option or defaulting 
to the set returned by test_generators().

TODO: wrapper around test_expect() for testing the parser.

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.

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

