package Template::TT3::Tag::Closed;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag',
    import    => 'class',
    utils     => 'blessed',
    patterns  => ':all',
    constants => 'HASH ARRAY REGEX NONE';

 
our $CHOMP_FLAGS    = qr/[-=~+]/;

1;

__END__
sub NEW_scan_start {
    my ($self, $input, $output, $text, $start, $pos) = @_;
    
    $self->debug("scan_start()  start token: $start_token  scanner: $scanner\n") if $DEBUG;

    # look for any pre_chomp flag or use the default
#    my $chomp = ($start_token =~ /($CHOMP_FLAGS)$/) ? $1 : $self->{ pre_chomp };
    my $chomp = ($$text =~ / \G ($CHOMP_FLAGS) /cgx) ? $1 : $self->{ pre_chomp };
    
    if ($chomp) {
        $chomp =~ tr/-=~+/1230/;
        $self->debug("prechomp flag: $chomp\n") if $DEBUG;
        # chomp off whitespace and newline preceding directive
        if ($chomp == CHOMP_ONE) { 
            $self->debug("prechomp one: [", $pretext->[TEXT], "]\n") if $DEBUG;
            $pretext->[TO] -= length($1)
                if $pretext->[TEXT] =~ s{ ((\n|^) [^\S\n]*) \z }{}mx;
        }
        elsif ($chomp == CHOMP_COLLAPSE) { 
            $self->debug("prechomp collapse: [", $pretext->[TEXT], "]\n") if $DEBUG;
            # the preceeding text has already been copied so we can safely
            # modify it by replacing trailing whitespace with a single space
            $pretext->[TO] -= length($1)
                if $pretext->[TEXT] =~ s{ (\s+) \z }{ }x;
        }
        elsif ($chomp == CHOMP_ALL) { 
            $self->debug("prechomp all: [", $pretext->[TEXT], "]\n") if $DEBUG;
            $pretext->[TO] -= length($1)
                if $pretext->[TEXT] =~ s{ (\s+) \z }{}x;
        }
        elsif ($chomp == CHOMP_NONE) {
            # do nothing
        }
        else {
            return $self->error("Invalid pre_chomp value: $chomp");
        }
    }
    
    # entire directive may be commented out
    if ($$text =~ /\G#/cg) {
        # TODO: store start token so we can report tag missing end tag better
        $$text =~ /$self->{ match_to_end }/cgx
            || return $self->error_msg( missing_end => $start_token );
        $self->scan_end($text, $2);
    }

    return $pretext;
}
        


1;

