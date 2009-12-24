package Template::TT3::Element::Pod::Command;

use Template::TT3::Class::Element
    version   => 2.69,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'pod_command',
    constants => 'DELIMITER',
    alias     => {
        value  => \&text,
        values => \&text,
    },
    messages  => {
        no_blank    => 'Missing blank line after %s Pod command',
        no_expect   => 'Missing =%s to end %s Pod command (got: %s)',
        bad_command => 'Invalid Pod command: %s',
    };


# The child elements that each command can accept in its content

our $ACCEPT = {
    pod   => 'head1 head2 head3 head4 over begin for',
    head1 => 'head2 head3 head4 over begin for',
    head2 => 'head3 head4 over begin for',
    head3 => 'head4 over begin for',
    head4 => 'over begin for',
    item  => 'over begin for',
    over  => 'over item begin for',
    begin => 'head1 head2 head3 head4 over for',
    for   => '',
};


# The terminating element that a command expects

our $EXPECT = {
    over  => 'back',
    begin => 'end',
};

# Split and merge the above into a single table

our $SCHEMA = {
    map { 
        $_ => { 
            name   => $_,
            expect => $EXPECT->{ $_ },
            accept => { 
                map { $_ => 1 } 
                split(DELIMITER, $ACCEPT->{ $_ }) 
            },
        }
    }
    keys %$ACCEPT
};


# elements that can be empty

our $EMPTY = {
    over => 1,
    back => 1,
};


#-----------------------------------------------------------------------
# parse method
#-----------------------------------------------------------------------

sub parse_expr {
    my ($self, $token, $scope) = @_;
    my $command = $self->[TOKEN];
    $command =~ s/^=//g;
    $self->[ARGS] = $command;
    
    $self->debug("[command:$command]") if DEBUG;

    # this command should have an entry in the $SCHEMA
    my $schema = $SCHEMA->{ $command }
        || return undef;   #$self->error_msg( bad_command => $command );

    # the outer command (or an implicit 'pod' scope if undefined) must 
    # accept this command as a nested content element
    my $stack  = $scope->{ pod_stack } ||= [ $SCHEMA->{ pod } ];
    my $parent = $stack->[-1];

    if ($parent->{ accept }->{ $command }) {
        $self->debug("$parent->{ name } scope accepts $command") if DEBUG;
    }
    else {
        $self->debug("$parent->{ name } scope rejects $command") if DEBUG;
        return undef;
    }
    
    # advance past the comment keyword
    $$token = $self->[NEXT];

    local $schema->{ body } = [ ];
    push(@$stack, $schema);
    $self->debug("$command schema: ", $self->dump_data($schema)) if DEBUG > 1;

    # skip any whitespace then parse the following block, allowing the block
    # to be empty if we're one of those special commands like 'over/back'
    $self->[EXPR] = $$token->skip_ws($token)->parse_block($token, $scope, 0, $EMPTY->{ $command })
        || return $self->fail_missing( $self->ARG_BLOCK => $token );

    # next token should be a blank line
    return $self->error_msg( no_blank => $command )
        unless $$token->eof || $$token->type eq 'pod_blank';

    if (DEBUG > 1) {
        $self->debug("parsed $command head: $self->[EXPR]");
        $self->debug("next token is $$token: $$token->[TOKEN]");
    }

    # then parse all the children
    $self->[BLOCK] = $$token->next_skip_ws($token)->parse_block($token, $scope, 0, 1)
        || return $self->fail_missing( 'Pod content' => $token );
    
    # if we have an element that we're expecting to terminate us then it
    # must appear next
    if ($schema->{ expect }) {
        $$token->is( '=' . $schema->{ expect }, $token )
            || return $self->error_msg( no_expect => $schema->{ expect }, $command, $$token->source );

        $$token = $$token->[NEXT]
            if $$token->type eq 'pod_blank';
    }
    
    pop(@$stack);
    $self->debug("[/command:$command]") if DEBUG;

    return $self;
}



sub text {
    my ($self, $context) = @_;
    my $name = $self->[ARGS];
    my $head = $self->[EXPR]  && $self->[EXPR]->text($context);
    my $body = $self->[BLOCK] && $self->[BLOCK]->text($context);
    return $context->show(
        "pod.command.$name" => {
            head => $head,
            body => $body,
        },
    );
}

# 
1;

__END__
over
sub prepare {
    my ($self, $parser) = @_;
    my $text = $self->{ text };
#    $self->debug("indent text: $text\n");
    $self->{ indent } = $text;
}

----


1;