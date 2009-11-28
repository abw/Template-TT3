package Template::TT3::Store;

use Carp;
confess __PACKAGE__, " is not ready for use yet";


__END__
use Template::TT3::Class
    version    => 2.71,
    debug      => 0,
    base       => 'Template::TT3::Base',
    utils      => 'tempfile',
#    constants  => 'UNICODE TT3_DOCUMENT',
    config    => [
        'extension|ext|class:EXTENSION',
        'directory|dir|class:DIRECTORY!',
    ],
    alias     => {
        destroy => \&clear,
    },
    messages   => {
        rename  => 'Failed to rename temporary file %s to %s: %s',
        loading => "Error loading compiled template %s: %s",
    };



use Badger::Storages
use Template::TT3::Document;        # find somewhere for this to go
    

sub init {
    my ($self, $config) = @_;

    # run the auto-generate configure method to massage parameters
    $self->configure($config);
    
    # create virtual filesystem rooted at specified directory
    $self->{ filesystem } = VFS->new( root => $self->{ directory } );

    # create base directory if it doesn't already exist
    Dir($self->{ directory })->must_exist(1);

    return $self;
}


sub get {
    my ($self, $id) = @_;
    my $file = $self->file($id);
    my $path = $file->definitive;
    my $object;

    $self->debug("get($id) from $file\n") if DEBUG;

    return undef
        unless $file->exists;

    # load the file using require(), first deleteing any
    # %INC entry to ensure it is reloaded - we don't want 
    # require() to return 1 to say it's already in memory
    delete $INC{ $path };
    eval { $object = require $path };

    return $@
        ? $self->error_msg( loading => $path, $@ )
        : $object;
}


sub set {
    my ($self, $id, $data) = @_;
    my $file = $self->file($id);
    my $path = $file->definitive;
    my $dir  = $file->parent;

    $self->debug("storing $id in file $path\n") if $DEBUG;
    
    # make sure parent directory exists or create it
    $dir->must_exist(1);

    my ($fh, $tmpfile) = tempfile( DIR => $dir->definitive, UNLINK => 1 );
    $self->debug("writing to temporary file: $tmpfile\n") if DEBUG;

    my $code = TT3_DOCUMENT->as_perl($data);

    # hack: Template::TT3::Document sets utf8 flag in $data if it detected
    # utf8 characters in generated Perl code.  This upwards notification 
    # allows us to set the :utf8 binmode on the output file handle.
    binmode $fh, ':utf8' if $data->{ utf8 };
    $fh->print($code);
    $fh->close;
    
    $self->debug("utf8 is ", $data->{ utf8 } ? 'on' : 'off') if DEBUG;
    $self->debug("wrote compiled Perl template:\n$code") if DEBUG;

    $self->debug("renaming into place as $path\n") if DEBUG;

    rename($tmpfile, $path)
        || $self->error_msg( rename => $tmpfile, $path, $! );
    

    return 1;
}

sub file {
    my ($self, $uri) = @_;
    my $ext  = $self->{ extension };
    my $path = $uri;

    # remove any colon from $uri, e.g. file:foo ==> file/foo or on
    # Win32, C:\Example ==> C\Example
    $path =~ s[:][]g;

    if (defined ($ext = $self->{ extension })) {
        # extension starting with word character (e.g. 'ttc') is 
        # appended to end of path, with '.' as separator, otherwise
        # we assume it's got it's own separator, e.g. '-ttc'
        $path .= ($ext =~ /^\w/)
            ? DOT.$ext
            :     $ext;
    }

    return $self->{ filesystem }->file($path);
}



1;

__END__


=head1 NAME

Template::Store - secondary storage of compiled templates

=head1 SYNOPSIS

    use Template::Store;

    my $store = Template::Store->new( 
        directory => '/tmp/tt3/store',
        extension => '.ttc',
    );

    # set() method to store Perl code in a file
    $store->set( foo => $foo_perl_code );

    # get() method to require() it back in again
    $foo_object = $store->get('foo')
        || die "foo is not in store\n";

=head1 DESCRIPTION

The Template::Store module implements a simple filesystem-based 
store, providing persistant storage of compiled templates.  It also
acts as a base class for other storage modules that store templates
using different media or mechanisms.

The Template::Store is a little like the Template::Cache module.  Both
are designed to save us from having to compile a template from source
code into Perl code whenever possible, given that this is the most
time consuming part of processing a template.  The key difference
between them is that the Template::Cache module stores live Perl
objects in memory, whereas Template::Store saves the compiled Perl
code on disk (or some other storage system).  However, both return
live Perl objects, from their get() method. In the case of
Template::Store, the file in which the component Perl code is stored
is loaded using Perl's require() function, causing the Perl code to be
loaded and evaluated into a Template::Component object.

=head2 METHODS

=head3 new()

Constructor method used to create a new store module.  The
C<directory> argument (or C<dir> for short) must be provided to define
the root directory under which compiled template files should be
stored.

    use Template::Store;

    my $store = Template::Store->new( 
        directory => '/tmp/tt3/store' 
    );

The optional C<extension> (or C<ext> for short) parameter can be
used to define an extension that will be automatically added to the
end of the name of each file used to store compiled templates.

    my $store = Template::Store->new( 
        directory => '/tmp/tt3/store' 
        extension => 'ttc' 
    );

If the extension begins with a word character, as shown in the
previous example, then it will be added to the end of the filename
with a C<.> character used to delimit them (e.g. ".ttc").  If the
extension already begins with a non-word character (e.g. ".ttc",
"-ttc", etc) then it is appended as it is with no further delimiter
added.

=head3 set($id, $perl_code)

Public method to store the Perl code generated for a compiled template
based on a unique identifier.  The C<$perl_code> argument should be 
provided as a scalar or reference to a scalar.

    my $perl_code = $compiler->compile($source_code);

    $store->set( foo => $perl_code );

=head3 get($id)

Public method to fetch an item from the store if it exists.  The unique
identifier is passed as the first argument.  The method loads the relevant
file associated with the identifier using Perl's require(), thereby evaluating
the Perl code and generating a Template::Component object (or whatever other
result the Perl code returned).

    my $foo = $store->get('foo')
        || die "foo not in store";

=head1 ERROR HANDLING

Any errors raised by the Template::Store module will be thrown as 
Template::Exception objects with a C<store> type.  This includes 
errors in the C<new()> constructor (e.g. no C<directory> defined), 
C<get()> and C<set()> methods (e.g. failed to read or write a file).

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 VERSION

$Revision: 1.3 $

=head1 COPYRIGHT

Copyright (C) 1996-2004 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


