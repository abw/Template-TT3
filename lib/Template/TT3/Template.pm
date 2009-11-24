package Template::TT3::Template;

use Template::TT3::Scope;
use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::Base',
    utils       => 'params self_params is_object',
    filesystem  => 'File',
    accessors   => 'text',
    constants   => 'GLOB',
    constant    => {
        SOURCE      => 'Template::TT3::Type::Source',
        SCOPE       => 'Template::TT3::Scope',
        CONTEXT     => 'Template::TT3::Context',
        SCANNER     => 'Template::TT3::Scanner',
        VARS        => 'Template::TT3::Variables',
        TREE        => 'Template::TT3::Type::Tree',
        TAG         => 'Template::TT3::Tag',
        FROM_TEXT   => 'template text',
        FROM_FH     => 'template read from filehandle',
    };

use Template::TT3::Type::Source 'Source';
use Template::TT3::Type::Tree 'Tree';
use Template::TT3::Variables;
use Template::TT3::Scanner;
use Template::TT3::Context;
use Template::TT3::Tag;

sub init {
    my ($self, $config) = @_;
    my $file;

    $self->{ name } = $config->{ name };
    
    # quick hack for now
    if ($file = $config->{ file }) {
        if (ref $file eq GLOB) {
            local $/ = undef;
            $self->{ text }   = <$file>;
            $self->{ name } ||= FROM_FH;
        }
        else {
            $self->{ file }   = File($file)->must_exist;
            $self->{ text }   = $self->{ file }->text;
            $self->{ name } ||= $file;
        }
    }
    elsif (defined $config->{ text }) {
        # TODO: should we alias or delete the original?
        $self->{ text }   = delete $config->{ text };
        $self->{ name } ||= FROM_TEXT;
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
    my $self    = shift;
    my $scanner = $self->scanner;
    return $self->scanner->scan(
        $self->source,
        undef,
        $self->scope,
    );
}

sub scanner {
    my $self = shift;
    return $self->{ scanner }
        ||= $self->SCANNER->new( $self->{ config } );
        # $self->{ config } );
}


sub scope {
    my $self = shift;
    return $self->{ scope }
       ||= $self->SCOPE->new( template => $self );
}
    

sub OLD_scanner {
    my $self = shift;
    return $self->{ scanner }
        ||= $self->SCANNER->new( tags => $self->tagset );
        # $self->{ config } );
}

sub OLD_tagset {
    my $self = shift;
    return $self->{ tagset } 
        ||= $self->init_tagset;
}

sub OLD_init_tagset {
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
    $self->debug("exprs: $exprs") if DEBUG;
    $exprs->sexpr;
#    join("\n", map { $_->sexpr } @$exprs);
}

sub exprs {
    my $self = shift;
    $self->{ exprs }
        ||= $self->parse;
}

sub tree {
    my $self = shift;
    return $self->{ tree }
        ||= $self->TREE->new( root => $self->exprs );
}

sub fill {
    my ($self, $params) = self_params(@_);
#    my $vars    = $self->VARS->new( data => $params );
    my $context = $self->CONTEXT->new( data => $params );
    $self->debug("fetching text from expressions") if DEBUG;
    return $self->exprs->text($context);
}


sub parse {
    my $self  = shift;
    my ($tokens, $token, $scope, $exprs);
        
    $exprs = eval {
        $tokens = $self->tokens;
        $token  = $tokens->first;
        $scope  = $self->scope;
        $token->parse_block(\$token, $scope);
    };
    
    unless ($exprs) {
        my $error = $@;
        die $error unless ref $error;           # TODO is_object
        $error->file( $self->{ name } );
        my $posn = $error->try->position;
        if ($posn) {
            $error->whereabouts(
                $self->source->whereabouts( position => $posn )
            );
        }
        $error->throw;
    }
    
    my @leftover;

    while (! $token->eof) {
        push(@leftover, $token->token);
        $token = $token->next;
    }
                
    if (@leftover) {
        $self->error("unparsed tokens: ", join('', @leftover));
    }
    
    $self->debug("template blocks: ", $self->dump_data($scope->{ blocks }))
        if DEBUG && $scope->{ blocks };

    return $exprs;
}


1;
