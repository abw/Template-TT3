package Template::TT3::Template;

use Template::TT3::Scope;
use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    import      => 'class',
    base        => 'Template::TT3::Base',
    utils       => 'params self_params is_object refaddr',
    filesystem  => 'File',
    accessors   => 'text file uri',
    config      => 'templates dialect uri',
    constants   => 'GLOB',
    constant    => {
        # TODO: rework all this to use Template::TT3::Modules
        SOURCE      => 'Template::TT3::Type::Source',
        SCOPE       => 'Template::TT3::Scope',
        CONTEXT     => 'Template::TT3::Context',
        TREE        => 'Template::TT3::Type::Tree',
        FROM_TEXT   => 'template text',
        FROM_FH     => 'template read from filehandle',
    };

use Template::TT3::Type::Source 'Source';
use Template::TT3::Type::Tree 'Tree';
use Template::TT3::Context;


sub init {
    my ($self, $config) = @_;
    my $file;

    $self->debug("init() with ", $self->dump_data($config))
        if DEBUG;

    # attach to the hub and link up to any templates provider
    $self->init_hub($config)
         ->configure($config);

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


#-----------------------------------------------------------------------
# the important methods that do shit
#-----------------------------------------------------------------------

sub _fill {
    my ($self, $params) = self_params(@_);

    $self->debug("filling with params: ", $self->dump_data($params))
        if DEBUG;

    return $self->block->text(
        $self->context( data => $params )
    );
}



#-----------------------------------------------------------------------
# methods to fetch/create delegates
#-----------------------------------------------------------------------

sub source {
    my $self = shift;
    return $self->{ source }
        ||= Source( $self->text );
}

sub dialect {
    my $self    = shift;
    my $dialect = $self->{ dialect };

    # updgrade a dialect name, e.g. 'TT3' to a dialect object
    $dialect = $self->{ dialect } = $self->hub->dialect( $dialect )
        unless ref $dialect;
    
    return $dialect;
}


sub scanner {
    my $self = shift;
    # TODO: do we need to cache the scanner?  Isn't it just one more thing
    # to worry about?
    return $self->{ scanner }
#        ||= $self->SCANNER->new( $self->{ config } );
        ||= $self->dialect->scanner;
}


sub scope {
    my $self = shift;
    return $self->{ scope }
       ||= $self->SCOPE->new( template => $self );
       # TODO: need to pass other stuff, like constants, etc.
       # $self->{ config } );
}


sub context {
    shift->CONTEXT->new(@_);
}

sub templates {
    my $self = shift;
    return $self->{ templates }
       ||= $self->{ config }->{ templates }
       ||= $self->hub->templates;
}


#-----------------------------------------------------------------------
# Scanning and parsing methods.  
#
# These are all implemented as "internal" methods with a '_' prefix.  We 
# generate public methods (without the '_' prefix) that wrap the internal 
# methods in an error handler that adds the filename and template source 
# extract to the exception.
#-----------------------------------------------------------------------

class->methods(
    map {
        my $priv = '_' . $_;         # private method has '_' prefix
        $_ => sub { 
            shift->catch( decorate_error => $priv  => @_ ) 
        }
    }
    qw( fill tree block parse tokens scan )
);


sub _tree {
    my $self = shift;
    return $self->{ tree }
        ||= $self->TREE->new( root => $self->_block );
}


sub _block {
    my $self = shift;
    $self->{ block }
        ||= $self->_parse;
}


sub _parse {
    my $self    = shift;
    my $tokens  = $self->_tokens;
    my $token   = $tokens->first;
    my $scope   = $self->scope;
    my $block   = $token->parse_block(\$token, $scope);
    my $remains = $token->remaining_text;
    
    # TODO: change this to a call on the element ->finish()
    if (defined $remains && length $remains) {
        $self->error("unparsed tokens: $remains");
    }
    
    $self->debug("template blocks: ", $self->dump_data($scope->{ blocks }))
        if DEBUG && $scope->{ blocks };

    return $block;
}


sub _tokens {
    my $self = shift;
    return $self->{ tokens }
        ||= $self->_scan;
}


sub _scan {
    my $self    = shift;
    my $scanner = $self->scanner;
    return $self->scanner->scan(
        $self->source,
        undef,
        $self->scope,
    );
}



#-----------------------------------------------------------------------
# error handling
#-----------------------------------------------------------------------

sub catch {
    my $self    = shift;
    my $handler = shift;
    my $result  = $self->try(@_);
    
    return $@ 
        ? $self->$handler( $@ )
        : $result;
}


sub decorate_error {
    my $self  = shift;
    my $error = shift || $self->reason;

    $self->debug("decorating error: $error") if DEBUG;

    # we can only decorate exception objects (TODO: test type)
    die $error unless ref $error;
        
    # add the template name to the exception object
    $error->file( $self->{ name } );
        
    # if the exception has a position method then we can use it to 
    # get an extract of the original source text
    my $posn = $error->try->position;
        
    if (defined $posn) {
        $error->try->whereabouts(
            $self->source->whereabouts( position => $posn )
        );
        $self->debug("decorated error: $error") if DEBUG;
    }
    elsif (DEBUG) {
        $self->debug("could not decorate error (no pos)");
    }

    $error->throw;
}



#-----------------------------------------------------------------------
# inspection / debuggging methods
#-----------------------------------------------------------------------

sub sexpr {
    shift->block->sexpr;
}


#-----------------------------------------------------------------------
# cleanup methods
#-----------------------------------------------------------------------

sub destroy_tokens {
    # TODO
}


sub destroy {
    my $self = shift;
    $self->destroy_tokens;
    delete $self->{ templates };
    delete $self->{ config    };
    delete $self->{ hub       };
}


sub DESTROY {
    shift->destroy;
}


1;

__END__


=head1 NAME

Template::TT3::Template - object representing a template

=head1 PARSING METHODS

=head2 tree()

Returns a L<Template::TT3::Type::Tree> object representing the element tree of
the parsed template. This is a thin wrapper around the block element returned
by the L<block()> method.  The tree is cached internally 

=head2 block()

Returns a L<Template::TT3::Element::Block> object representing the main block
of a parsed template.  This is generated by calling the L<parse()> method.
The block is cached internally once parsed.

=head2 parse()

This method parses the tokens returned by the L<tokens()> method and returns a
L<Template::TT3::Element::Block> object representing the template expressions.

=head2 tokens()

This returns a C<Template::TT3::Tokens> object representing the list of tokens
scanned from the template source.  The tokens are generated by the L<scan()>
method and cached internally.

=head2 scan()

=head1 ERROR HANDLING METHODS

=head2 catch($handler, $method, @args)

This method can be used to call another method with a C<try...catch>
wrapper around it.  Any errors caught are forwarded to the C<$handler>
method.

The L<tree()>, L<block()>, L<scan()> and various other public methods are
implemented as thin wrappers around internal L<_tree()>, L<_block()>,
L<_scan()>, etc., methods.  They use the L<catch()> method something like
this:

    sub tree {
        my $self = shift;
        return $self->catch( decorate_error => _tree => @_ );
    }

This calls the C<_tree()> method, passing all the arguments C<@_> that
were passed to the C<tree()> method.  If an error is thrown then the 
C<decorate_error()> method is called.

=head2 decorate_error($exception)

This method is called (typically by the L<catch()> method) to decorate an 
exception object passed to it.  It adds the template name to the exception
and, if the error has a element token attached to, an extract of the template
source where the error occurred.  This allows the exception object to report
a more useful error message.

=head2 INTERNAL METHODS

The following methods are the internal implementations of their corresponding
public methods (of the same name, but without the leading underscore). The
public methods are wrappers around these internal methods that add some extra
functionality for the purpose of better error reporting. 

There's nothing to stop you from calling these methods directly but if you do
then you won't get the template name and source extract added to the error
message. If you're writing an internal method that will end up being wrapped
in its own public method then you can and should call these methods directly.
Otherwise you'll be invoking the catch handler twice (or more) for each error
thrown.

=head2 _tree()

=head2 _block()

=head2 _parse()

=head2 _tokens()

=head2 _scan()

1;
