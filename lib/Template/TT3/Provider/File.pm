package Template::TT3::Provider::File;

use Template::TT3::Class
    version    => 2.71,
    debug      => 0,
    base       => 'Template::TT3::Provider',
    constants  => ':scheme',
    filesystem => 'VFS',
    messages   => {
        no_path => 'No path (or root) specified for file provider',
    };


sub init {
    my ($self, $config) = @_;
    
    $self->debug("init() with ", $self->dump_data($config))
        if DEBUG;

    my $path = $config->{ path } || $config->{ root }
        || return $self->error_msg('no_path');
        
    $self->{ VFS } = VFS->new( root => $path );

    $self->debug("Created virtual filesystem for $path : $self->{ VFS }")
        if DEBUG;

    $self->{ config } = $config;

    return $self;
}

    
sub fetch {
    my ($self, $path) = @_;

    $self->debug("file provider looking for $path")
        if DEBUG;

    my $file = $self->{ VFS }->file($path);

    return $self->decline( not_found => File => $path )
        unless $file->exists;

    my $config = $self->{ config };

    $self->debug("file provider returning file $file")
        if DEBUG;

    return {
        file     => $file, 
        id       => FILE_SCHEME.COLON.$file->definitive,
        path     => $file->absolute,
        dialect  => $config->{ dialect },
#        loaded   => time,
#        modified => $file->modified,
        # TODO: add other options.
        # TODO: add url as definitive path
    };
}


1;

__END__

=head1 NAME

Template:TT3::Provider::File - template provider for files

=head1 SYNOPSIS

    use Template::TT3::Provider::File;
    
    # specify either a single path...
    my $provider = Template::TT3::Provider::File->new(
        path => '/path/to/your/templates',
    );
    
    # ...or multiple paths
    my $provider = Template::TT3::Provider::File->new(
        path => [
            '/path/to/your/templates/one',
            '/path/to/your/templates/two',
        ],
    );
    
    # then fetch templates
    my $template = $provider->fetch('example.tt3')
        || die $provider->reason;

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Provider> for providing
templates from a filesystem. It is a thin wrapper around the
L<Badger::Filesystem::Virtual> module.

=head1 METHODS

This module implements the following methods in addition to, or replacing
those inherited from the L<Template::TT3::Provider>, L<Template::TT3::Base>
and L<Badger::Base> base classes.

=head2 init()

Custom initialisation method called by the L<new()|Badger::Base/new()>
constructor method inherited from L<Badger::Base>. It expects to be passed
either of a L<path> or L<root> parameter (the two are interchangeable) 
indicating the root directory of the templates.

    my $provider = Template::TT3::Provider::File->new(
        path => '/path/to/your/templates',
    );

It creates a L<virtual filesystem|Badger::Filesystem::Virtual> object to
manage the files under that root directory. Files are always resolved relative
to this root directory. Files located outside of the root directory will not
be accessible.

You can specify multiple directories by providing an array reference as the 
L<path>.

    my $provider = Template::TT3::Provider::File->new(
        path => [ 
            '/path/to/your/templates/one',
            '/path/to/your/templates/two',
        ],
    );

=head2 fetch($uri)

This method fetches a template from the filesystem identified by the C<$uri> 
argument.  This should be a regular file path, e.g. C<bar.tt3>, C</foo/bar.tt3>,
etc.  Both relative and absolute paths are resolved with respect to the 
root L<path> of the virtual filesystem.

    my $template = $provider->fetch('example.tt3')
        || die $provider->reason;

It returns a hash array containing a C<file> item which references a
L<Badger::Filesystem::File> object and a C<uri> indicating the definitive path
(i.e. the absolute path, including the root directory of the virtual
filesystem) of the template.  e.g.

    {
        file => $VFS->file('/local/path.tt3'),
        uri  => '/path/to/your/templates/two/local/path.tt3',
    }

If the file cannot be found then the method returns C<undef>.  An error 
message (or strictly speaking, a I<decline> message, as no error is deemed
to have occurred) is available via the L<reason()|Badger::Base/reason()>
method inherited from L<Badger::Base>.

If an error occurs then an L<exception|Badger::Exception> will thrown. 

=head1 CONFIGURATION OPTIONS

=head2 root / path

The C<root> parameter is used to specify the path to the template directory.
It may be specified as a single directory name, a
L<Badger::Filesystem::Directory> object) or as a reference to an array of
either of the above.

Here's an example using a regular directory path.

    my $provider = Template::TT3::Provider::File->new(
        root => '/path/to/your/templates',
    );

And here's the same thing using a L<Badger::Filesystem::Directory> object.

    use Badger::Filesystem 'Dir';
    
    my $provider = Template::TT3::Provider::File->new(
        root => Dir('/path/to/your/templates'),
    );

This example shows two directory paths being specified.

    # ...or an array reference to multiple paths...
    my $provider = Template::TT3::Provider::File->new(
        root => [ 
            '/path/to/your/templates/one',
            '/path/to/your/templates/two',
        ],
    );

And here's the same thing using L<Badger::Filesystem::Directory> objects.

    use Badger::Filesystem 'Dir';
    
    my $tdir = Dir('/path/to/your/templates');
    
    my $provider = Template::TT3::Provider::File->new(
        root => [ 
            $tdir->dir('one'),      # /path/to/your/templates/one
            $tdir->dir('two'),      # /path/to/your/templates/two
        ],
    );

C<path> is an alias for C<root>.  The L<Badger::Filesystem::Virtual> module
expects a C<root> parameter, but C<path> is the more familiar terms used in 
TT3 (C<template_path>, C<plugin_path>, etc).  So we support either 

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>,
L<Template::TT3::Base>,
L<Template::TT3::Provider>,
L<Template::TT3::Providers>,
L<Template::TT3::Provider::Cwd>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

