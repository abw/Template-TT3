package Template::TT3::Scanner::Pod;

#use Badger::Pod 'Pod';
use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Scanner',
    config     => [
        'merge_verbatim=1',
    ],
    constant   => {
        PADDED   => -1,
    };


# whitespace, blank lines, separators, etc.
our $BLANK          = qr/ [ \t\x{85}\x{2028}\x{2029}] /x;
our $BLANK_LINE     = qr/ $BLANK* \n /x;
our $BLANK_LINES    = qr/ \n $BLANK_LINE+ /x;
our $WHITE_LINE     = qr/ $BLANK+ \n /x;
our $WHITE_LINES    = qr/ ^ $BLANK* \n $WHITE_LINE+ $ /x;
our $PARA_SEPARATOR = qr/ ($BLANK_LINES | $) /x;

# embedded format strings
our $FORMAT_START   = qr/ ([A-Z]) ( < (?: <+ \s )? ) /x; 
our $FORMAT_END     = qr/ ( (?: \s >+ )? > ) /x; 
our $FORMAT_TOKEN   = qr/ (?: $FORMAT_START | $FORMAT_END ) /x;

# miscellaneous patterns
our $OPTION_LINE    = qr/ (?: $BLANK+ .* )? (?: \n | $ ) /x;
our $COMMAND_WORD   = qr/ (=\w+) /x;
our $COMMAND_LINE   = qr/ $COMMAND_WORD ($BLANK* [^\n]*?) /x;
our $COMMAND_FORMAT = qr/ ^ $BLANK* (\S+) $BLANK* $PARA_SEPARATOR /x;

# main scanning regexen
our $SCAN_TO_EOF    = qr/ \G (.+) /sx;
our $SCAN_TO_POD    = qr/ \G ( \A | .*? $BLANK_LINES) $COMMAND_WORD /smx;
our $SCAN_TO_CUT    = qr/ \G ( \A | .*? $BLANK_LINES =cut $OPTION_LINE | .*) /smx;
our $SCAN_TO_CODE   = qr/ ($SCAN_TO_CUT | $SCAN_TO_EOF) /x;
our $SCAN_TO_END    = qr/ \G (.*? $BLANK_LINES) =end ($OPTION_LINE) /smx; 
our $SCAN_COMMAND   = qr/ \G $COMMAND_LINE $PARA_SEPARATOR /smx;
our $SCAN_VERBATIM  = qr/ \G ($BLANK+ .*?) $PARA_SEPARATOR /smx;
our $SCAN_PARAGRAPH = qr/ \G (.+?)         $PARA_SEPARATOR /smx;
our $SCAN_FORMAT    = qr/ \G (.*?)         $FORMAT_TOKEN   /smx;

# custom command handlers
our $COMMANDS = {
    '=cut' => \&parse_command_cut,
};

# expand tabs to 4 spaces by default
our $TAB_WIDTH = 4;


sub init {
    my ($self, $config) = @_;
    $self->debug("INIT: ", $self->dump_data($config)) if DEBUG;

    $self->configure($config);
    $self->{ config } = $config;

    return $self;
}


sub tokenise {
    my ($self, $input, $output, $scope) = @_;
    my ($pos, $code, $pod);

    $self->{ para } = 1;

    while (1) {
        $pos = pos $$input || 0;
        
        if ($$input =~ /$SCAN_TO_POD/cg) {
            # scanned a block of text up to the first Pod command
            ($code, $pod) = ($1, $2);

            # leading text can be empty if Pod =cmd starts on the first character 
            if (length $code) {
                $output->token('pod.code', $code, $pos);
                $pos += length $code;
            }
        
            if ($$input =~ /$SCAN_TO_CODE/cg) {
#                $self->error("scanned to code: ", $input->debug_lookahead);
                $pod .= $1;
                $self->parse_pod($input, $output, $scope, $pod, $pos);
            }
            else {
#                $self->error("failed to scan to code: ", $input->debug_lookahead);
            }
        }
        elsif ($$input =~ /$SCAN_TO_EOF/) {
            # consume any remaining text after the last (or no) pod command
            $output->token('pod.code', $1, $pos) if length $1;
            last;
        }
        else {
            last;
        }
    }
    
    # add the terminator that marks the end of file
    $output->eof_token('', pos $$input );
    
    return $output->finish;
}


sub parse_pod {
    my ($self, $input, $output, $scope, $pod, $pos) = @_;
    my ($name, $body, $gap, $len, $method);
    my $vmerge = $self->{ merge_verbatim } || 0;
    my $vtabs  = $self->{ expand_tabs };
    my $vtab   = ' ' x ($self->{ tab_width } || $TAB_WIDTH) if $vtabs;
    my $off    = 0;

    $self->debug("parsing pod") if DEBUG;

    # trim any trailing whitespace (not sure why... perhaps legacy code?)
    $pod =~ s/\s+$//g;
    
    while (1) {
        $self->debug("parse_pod(): ", $input->debug_lookahead) if DEBUG;
        
        if ($pod =~ /$SCAN_COMMAND/cg) {
            # a command is a paragraph starting with '=\w+'
            ($name, $body, $gap) = ($1, $2, $3);
            $self->debug("CMD [$name] [$body] [$gap]") if DEBUG;

            $len = length($name) + length($body);

            if ($method = $COMMANDS->{ $name }) {
                $self->debug("calling custom method for $name") if DEBUG;
                $self->$method($input, $output, $scope, $name, $body, $pos);
                $output->token('whitespace', $gap, $pos + $off + $len);
            }
            else {
                $self->parse_command($input, $output, $scope, $name, $body, $pos);

                # followed by a blank line - we use a special terminating token
                # (pod.blank instead of just whitespace) so that the command
                # can tell when the headline ends and the body starts
                $output->token('pod.blank', $gap, $pos + $off + $len);
            }

        }
        elsif ($pod =~ /$SCAN_VERBATIM/cg) {
            # a verbatim block starts with whitespace
            ($body, $gap) = ($1, $2);

            if ($vmerge) {
                # merge_verbatim can be set to PADDED to only merge 
                # consecutive verbatim paragraphs if they are separated by 
                # line(s) that contain at least one whitespace character,
                # any other true value value merges them unconditionally
                while ( 
                    ($vmerge == PADDED ? $gap =~ $WHITE_LINES : 1) 
                    && $pod =~ /$SCAN_VERBATIM/cg ) {
                    $body .= $gap . $1;
                    $gap = $2;
                }
            }

            # expand tabs if expand_tabs option set
            $len = length $body;
            $body =~ s/\t/$vtab/g if $vtabs;

            # add the verbatim paragraph, then the blank line
            $output->token('pod.verbatim', $self->undent($body), $pos + $off);
            $output->token('whitespace', $gap, $pos + $off + $len);
        }
        elsif ($pod =~ /$SCAN_PARAGRAPH/cg) {
            # a regular paragraph is anything that isn't command or verbatim
            ($body, $gap) = ($1, $2);
            $self->parse_paragraph($input, $output, $scope, $body, $pos + $off);
            $output->token('whitespace', $gap, $pos + $off + length $body);
        }
        else {
            # the $SCAN_PARAGRAPH regex will gobble any remaining characters
            # to EOF, so if that fails then we've exhausted all the input
            last;
        }

        # update line count and paragraph count
        $self->{ para }++;
        $pos = pos $pod;
    }
}


sub parse_command {
    my ($self, $input, $output, $scope, $name, $head, $pos) = @_;
    $output->token('pod.command', $name, $pos);
    $self->parse_formatted($input, $output, $scope, $head, $pos + length $name);
}


sub parse_paragraph {
    my ($self, $input, $output, $scope, $text, $pos) = @_;
    $output->token('pod.paragraph', $text, $pos);
    $self->parse_formatted($input, $output, $scope, $text, $pos);
}


sub parse_formatted {
    my ($self, $input, $output, $scope, $text, $pos) = @_;
    my ($body, $name, $paren, $lparen, $rparen, $format, $where, $len);
    $self->debug("parse_paragraph($text)") if DEBUG;

    my $off = 0;
    #    $text =~ /^\s*/scg;

    $self->debug("parse_formatted() at pos $pos\n") if DEBUG;
    
    while ($text =~ /$SCAN_FORMAT/cg) {
        ($body, $name, $lparen, $rparen) = ($1, $2, $3, $4);
        
        if ($len = length $body) {
            $output->token('text', $body, $pos + $off);
            $off += $len;
        }

        if (defined $name) {
            $self->debug("format start @ $pos: $name$lparen\n") if DEBUG;
            # construct right paren that we expect to match (without spaces)
            for ($rparen = $lparen) {
                s/\s$//;
                tr/</>/;
            }
            $output->token('pod.format.start', $name, $pos + $off, $lparen, $rparen);
        }
        elsif (defined $rparen) {
            $self->debug("format end @ $pos: $rparen\n") if DEBUG;
            # strip whitespace for comparison against expected rparen
            if ($rparen =~ s/^(\s+)//) {
                $output->token('whitespace', $1, $pos + $off);
                $off += length $1;
            }

            $output->token('pod.format.end', $rparen, $pos + $off);
        }
        $off = pos($text);
    }
    if ($text =~ /$SCAN_TO_EOF/g) {
        $output->token('text', $1, $pos + $off);
    }
}


sub parse_command_cut {
    my ($self, $input, $output, $scope, $name, $head, $pos) = @_;
    $output->token('whitespace', $name, $pos);
    $self->{ TMP_DONE_CUT } = 1;            # TMP
#    $self->todo;
    # =cut must not appear as the first command paragraph in a POD section
#    $self->warning( bad_cut => $line )
#        if $self->{ para } == 1;
}


sub parse_command_pod {
    my ($self, $input, $output, $scope, $name, $head, $pos) = @_;
    $self->todo;
    
    # =pod should not appear anywhere other than the first command
#    $self->warning( bad_pod => $line )
#        unless $self->{ para } == 1;
}

sub undent {
    my $self = shift;
    my $text = shift;
    my (@lines, $line, $length, $min);
    my $save = $text;

    for ($text) {
        s/\t/    /g;
        s/^ *\n//;
        s/(\n *)*$//;
        @lines = split(/\n/);
    }

    # some arbitrarily large number
    $min = 100;

    foreach (@lines) {
        chomp;
        next if s/^\s+$//;
        /^(\s*)/;
        $length = length $1;
        $min = $length if $length < $min;
    }

    if ($min) {
        foreach (@lines) {
            s/^ {$min}//mg;
        }
    }

    $text = join("\n", @lines);
    
    $self->debug("undented text:\nBEFORE [\n$save\n]\nAFTER [[\n$text\n]\n")
        if DEBUG;
    
    return $text;
}

1;
