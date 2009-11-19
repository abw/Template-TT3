package Template::TT3::View;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::Base',
    constants => 'ARRAY BLANK',
    messages  => {
        bad_method => qq{Can't locate object method "%s" via package "%s" at %s line %s},
        no_view    => 'No view method defined for %s',
    };

our $TRIM_TEXT = 64;


sub init {
    my ($self, $config) = @_;
#    $self->{ file   } = $config->{ file   };
#    $self->{ line   } = $config->{ line   } || 1;
    $self->{ indent } = $config->{ indent } || 0;
    $self->{ pad    } = ' ' x $self->{ indent };
    return $self;
}

sub indent {
    my ($self, $text) = @_;
    $text =~ s/^/$self->{ pad }/gm if $self->{ indent };
    return $text;
}

sub emit {
    my $self = shift;
    join(
        BLANK,
        grep { defined }
        map  { ref $_ eq ARRAY ? @$_ : $_ }
        @_
    );
}

sub tidy_text {
    my ($self, $text) = @_;
	my $len = shift || $TRIM_TEXT;
    $text =~ s/\n/\\n/g;
    $text =~ s/\t/\\t/g;
    $text = substr($text, 0, $len) . '...' 
        if $len && length($text) > $len - 3;
    return $text;
}

1;
