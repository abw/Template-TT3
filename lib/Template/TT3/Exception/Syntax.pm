package Template::TT3::Exception::Syntax;

use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Badger::Exception',
    utils      => 'self_params',
    mutators   => 'file line position column element token source';
    

our $FORMAT = 'TT3 Syntax Error at line <line> of <file>: <info>';
#\n    <source>\n    <marker>';


sub init {
    my ($self, $config) = @_;
    $self->SUPER::init($config);
#    my $element = $config->{ element };
#    my $token   = $config->{ token   };
    $self->{ element  } = $config->{ element  };
    $self->{ token    } = $config->{ token    };
    $self->{ extract  } = $config->{ extract  };
    $self->{ position } = $config->{ position };
    $self->{ column   } = $config->{ column   };
    return $self;
}


sub whereabouts {
    my ($self, $params) = self_params(@_);
    # quick hack
    @$self{ keys %$params } = values %$params;
    return $self;
}


# hack to over-ride default text() which adds file/line at end
sub text {
    my $self = shift;
    my $text = shift || $self->class->any_var('FORMAT');
    $text  =~ s/<(\w+)>/defined $self->{ $1 } ? $self->{ $1 } : "(no $1)"/eg;
    my $extract = $self->{ extract };
    my $column  = $self->{ column };
#    $self->debug("source: [$source]   column: [$column]\n");
    $text .= "\nSource: $extract" if defined $extract;
    $text .= "\n       " . (' ' x $column) . '^ here' if defined $extract && defined $column;
    $text .= "\n";
    return $text;
}



1;