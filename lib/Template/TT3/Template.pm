package Template::TT3::Template;

use Template::TT3::Scope;
use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    import      => 'class',
    base        => 'Template::TT3::Base',
    utils       => 'params self_params is_object refaddr',
    filesystem  => 'File',
    accessors   => 'file uri name id',
    config      => 'templates dialect id uri source',
    modules     => 'IO_HANDLE',
    constants   => 'GLOB :from',
    constant    => {
        # TODO: rework all this to use Template::TT3::Modules
        SOURCE      => 'Template::TT3::Type::Source',
        SCOPE       => 'Template::TT3::Scope',
        TREE        => 'Template::TT3::Type::Tree',
    },
    messages => {
        no_text    => 'The text is not available for %s',
    };

use Template::TT3::Type::Source 'Source';
use Template::TT3::Type::Tree 'Tree';


sub init {
    my ($self, $config) = @_;
    my $file;

    $self->debug("init() with ", $self->dump_data($config))
        if DEBUG;

    # attach to the hub and link up to any templates provider
    $self->init_hub($config)
         ->configure($config);

    $self->{ name } = $config->{ name };
    
    # look for the sources items we can accept in order from "highest"
    # to "lowest": file, text, code, block
    
    if ($file = $config->{ file }) {
        # There's some duplication here with what's going on in the various
        # template fetching methods of Template::TT3::Templates.  But I think
        # it's probably a good thing for templates to be reasonably self-
        # sufficient so that a programmer can just create a template object
        # that loads itself from text, file or filehandle without requiring
        # all the template providing machinery of T::TT3::Templates.
        if (ref $file eq GLOB) {
            $self->{ text }   = $self->hub->input_glob($file);
            $self->{ name } ||= FROM_HANDLE;
        }
        elsif (ref $file eq IO_HANDLE) {
            $self->{ text }   = $self->hub->input_handle($file);
            $self->{ name } ||= FROM_HANDLE;
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
    elsif (defined $config->{ code }) {
        $self->{ text }   = delete $config->{ text };
        $self->{ name } ||= FROM_CODE;
        $self->{ code }   = $config->{ code };
    }
    elsif (defined $config->{ block }) {
        $self->{ text  }   = delete $config->{ text };
        $self->{ name  } ||= FROM_CODE;
        $self->{ block }   = $config->{ block };
    }
    else {
        return $self->error_msg( missing => 'text, file or code' );
    }

    $self->{ config   } = $config;

    return $self;
}


#-----------------------------------------------------------------------
# the important methods that do shit
#-----------------------------------------------------------------------

sub service {
    my $self = shift;   

    return sub {
        my $env = params(@_);
        $env->{ context }
            ->visit($self)
            ->run
    };
}

sub _fill {
    my ($self, $params) = self_params(@_);

    $self->debug("filling with params: ", $self->dump_data($params))
        if DEBUG;

    return $self->_fill_in(
        $self->context( data => $params )
    );
}


sub _fill_in {
    my ($self, $context) = @_;

    $self->debug("filling in context: $context")
        if DEBUG;

    return $context->visit($self)->_run;

#    return $self->_run($context);

#    return $self->code->($context);
# context visit() should return a Visit object which wraps 
#   return $context->visit($self)->run;

}


sub _run {
    my $self = shift;
    $self->_code->(@_);
}



#-----------------------------------------------------------------------
# temporary hack to get HTML output working
#-----------------------------------------------------------------------

sub _fill_html {
    my ($self, $params) = self_params(@_);
    return $self->_fill_html_in(
        $self->context( data => $params )
    );
}


sub _fill_html_in {
    my ($self, $context) = @_;
    return $context->visit($self)->_html;
}


sub _html {
    my $self = shift;
    $self->_block->html(@_);
}




#-----------------------------------------------------------------------
# methods to fetch/create delegates
#-----------------------------------------------------------------------

sub text {
    my $self = shift;
    return $self->error_msg( no_text => $self->name )
        unless defined $self->{ text };
    return $self->{ text };
}


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
       ||= $self->SCOPE->new( 
           template => $self,
           source   => $self->source,
       );

       # TODO: need to pass other stuff, like constants, etc.
       # $self->{ config } );
}


sub context {
    my $self   = shift;
    my $params = params(@_);
    # TODO: should this get hub context and then clone it?
    return $self->hub->context->child(@_);
#        templates => $self->{ templates },
#        hub       => $self->{ hub },
#        @_
#    );
}

sub templates {
    my $self = shift;
    return $self->{ templates }
       ||= $self->{ config }->{ templates }
       ||= $self->hub->templates;
}


sub metadata {
    my $self = shift;
    my $meta = $self->{ metadata } ||= { };

    # return the metadata hash when called without args
    return $meta unless @_;

    if (@_ == 1 && ! ref $_[0]) {
        # single non-reference name is a lookup request: $t->metadata('title')
        return $meta->{ $_[0] };
    }
    else {
        # single hash ref or list of named params provide new metadata
        my $params = params(@_);
        $self->debug("adding metadata to template: ", $self->dump_data($params))
            if DEBUG;
        @$meta{ keys %$params } = values %$params;
    }

    return $meta;
}


sub tt_dot {
    my ($self, $name, @args) = @_;

    if (exists $self->{ metadata }->{ $name }) {
        $self->debug("found metadata item for $name: $self->{ metadata }->{ $name }")
            if DEBUG;
        return $self->{ metadata }->{ $name };
    }

    # TODO: throw error?
    return undef;
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
    qw( fill fill_in fill_html fill_html_in code compile tree block parse tokens scan )
);


sub _code {
    my $self = shift;
    return $self->{ code }
        ||= $self->_compile;
}   


sub _compile {
    my $self  = shift;
    my $block = $self->_block;
    return sub {
        $block->text(@_)
    };
}        


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
    my $self = shift;
    # TODO: fails if template is empty - first token is EOF
    $self->_tokens->first->parse(
        $self->scope
    );
}


sub _tokens {
    my $self = shift;
    return $self->{ tokens }
        ||= $self->_scan;
}


sub _scan {
    my $self    = shift;
    my $scanner = $self->scanner;

    $self->debug("Scanning source of $self->{ name }") 
        if DEBUG;

    return $self->scanner->scan(
        $self->source,
        undef,
        $self->scope,
    );
}



# TODO: figure out where these should go

sub vars {
    my $self = shift;
    return $self->tree->view_vars(
        template => $self,
        source   => $self->source,
    );
}

sub vars_HTML {
    my $self = shift;
    return $self->tree->view_vars_HTML(
        template => $self,
        source   => $self->source,
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
    
    # don't try and decorate an error twice
    $error->throw if $error->try->decorated;
        
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
