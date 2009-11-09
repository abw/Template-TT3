package Template::TT3::Template;

use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::Base',
    utils       => 'params self_params is_object',
    filesystem  => 'File',
    accessors   => 'text',
    constants   => 'GLOB',
    constant    => {
        SOURCE  => 'Template::TT3::Type::Source',
        SCANNER => 'Template::TT3::Scanner',
        VARS    => 'Template::TT3::Variables',
        TAG     => 'Template::TT3::Tag',
    };

use Template::TT3::Type::Source 'Source';
use Template::TT3::Variables;
use Template::TT3::Scanner;
use Template::TT3::Tag;

sub init {
    my ($self, $config) = @_;
    my $file;

    # quick hack for now
    if ($file = $config->{ file }) {
        if (ref $file eq GLOB) {
            local $/ = undef;
            $self->{ text } = <$file>;
        }
        else {
            $self->{ file } = File($file)->must_exist;
            $self->{ text } = $self->{ file }->text;
        }
    }
    elsif (defined $config->{ text }) {
        # TODO: should we alias or delete the original?
        $self->{ text } = delete $config->{ text };
    }
    else {
        return $self->error_msg( missing => 'text or file' );
    }

    $self->{ config } = $config;

    return $self;
}


sub source {
    my $self = shift;
    return $self->{ source }
        ||= Source( $self->text );
}


sub tokens {
    my $self = shift;
    return $self->{ tokens }
        ||= $self->scan;
}

sub scan {
    my $self = shift;
    my $scnaner = $self->scanner;
    return $self->scanner->scan(
        $self->source
    );
}

sub scanner {
    my $self = shift;
    return $self->{ scanner }
        ||= $self->SCANNER->new( tags => $self->tagset );
        # $self->{ config } );
}

sub tagset {
    my $self = shift;
    return $self->{ tagset } 
        ||= $self->init_tagset;
}

sub init_tagset {
    my $self   = shift;
    my $dirtag = TAG->new(
        start => '[%',
        end   => '%]',
    );
    return [$dirtag];
}

sub sexpr {
    my $self  = shift;
    my $exprs = $self->exprs;
    $self->debug("exprs: $exprs");
    $exprs->sexpr;
#    join("\n", map { $_->sexpr } @$exprs);
}

sub exprs {
    my $self = shift;
    $self->{ exprs }
        ||= $self->parse;
}

sub fill {
    my ($self, $params) = self_params(@_);
    my $vars    = $self->VARS->new( data => $params );
    my $context = { variables => $vars };
    return $self->exprs->text($context);
}


sub parse {
    my $self   = shift;
    my $tokens = $self->tokens;
    my $token  = $tokens->first;
    my $exprs  = $token->as_exprs(\$token);
    my @leftover;

    while (! $token->eof) {
        push(@leftover, $token->token);
        $token = $token->next;
    }
                
    if (@leftover) {
        $self->error("unparsed tokens: ", join('', @leftover));
    }

    return $exprs;
}


1;
