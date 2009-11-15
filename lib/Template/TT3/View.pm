package Template::TT3::View;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::Base',
    constants => 'ARRAY BLANK',
    messages  => {
        bad_method => qq{Can't locate object method "%s" via package "%s" at %s line %s},
    };


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

1;
