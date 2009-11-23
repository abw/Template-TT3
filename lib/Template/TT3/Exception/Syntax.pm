package Template::TT3::Exception::Syntax;

use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    base       => 'Badger::Exception',
    utils      => 'self_params random_advice',
    mutators   => 'file line position column element token source';
    

our $FORMAT = 'TT3 syntax error at line <line> of <file>:<error><advice><source><marker>';
our $ERROR  = "\n    Error: %s";
our $SOURCE = "\n   Source: %s";
our $ADVICE = "\n   Advice: %s";
our $MARKER = "\n%s^ here";
our $RANDOM = 0;

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
    my $self    = shift;
    my $format  = shift || $self->class->any_var('FORMAT');
    my $error   = shift || $self->class->any_var('ERROR');
    my $source  = shift || $self->class->any_var('SOURCE');
    my $marker  = shift || $self->class->any_var('MARKER');
    my $extract = $self->{ extract };
    my $column  = $self->{ column };
    my $vars    = { 
        %$self,
        error => sprintf($error, $self->{ info }),
    }; 

    $vars->{ source } = defined $extract
        ? sprintf($SOURCE, $extract)
        : '';

    $vars->{ marker } = defined $extract && defined $column
        ? sprintf($MARKER, ' ' x ($column + 10))
        : '';
    
    # just for testing - there should be a hook for for further info
    $vars->{ advice } = $RANDOM
        ? sprintf($ADVICE, random_advice)
        : '';
        
    $format =~ s/<(\w+)>/defined $vars->{ $1 } ? $vars->{ $1 } : "(no $1)"/eg;
    $format .= "\n";
    return $format;
}



1;