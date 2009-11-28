package Template::TT3::Provider::Cwd;

use Template::TT3::Class
    version    => 2.71,
    debug      => 0,
    base       => 'Template::TT3::Provider',
    filesystem => 'Cwd';


sub init {
    my ($self, $config) = @_;
    
    $self->{ cwd } = Cwd;

    $self->debug("Created filesystem provider for current working directory: $self->{ cwd }")
        if DEBUG;
    
    return $self;
}

    
sub fetch {
    my ($self, $path) = @_;

    $self->debug("cwd provider looking for $path")
        if DEBUG;

    my $file = $self->{ cwd }->file($path);
    
    return $file->exists
        ? { file => $file, uri => $file->path }
        : $self->decline( not_found => File => $path );
        
}

1;

__END__

=head1 NAME

Template:TT3::Provider::Cwd - template provider for files in the current working directory

=head1 SYNOPSIS

    use Template::TT3::Provider::Cwd;
    
    my $provider = Template::TT3::Provider::Cwd->new;
    
    # all files are resolved relative to the current working directory
    my $template = $provider->fetch('example.tt3')
        || die $provider->reason;
        
    my $template = $provider->fetch('subdir/example.tt3')
        || die $provider->reason;
        
    my $template = $provider->fetch('../../updir/example.tt3')
        || die $provider->reason;

=head1 DESCRIPTION

This module is a subclass of L<Template::TT3::Provider> for providing
templates relative to the current working directory.  It is the default
provider used when no L<template_path|Template::TT3::Manual::Config/templatep_path>
option is defined.

=head1 METHODS

This module implements the following methods in addition to, or replacing
those inherited from the L<Template::TT3::Provider>, L<Template::TT3::Base>
and L<Badger::Base> base classes.

=head2 init()

Custom initialisation method called by the L<new()|Badger::Base/new()>
constructor method inherited from L<Badger::Base>.  It does not accept any
configuration parameters.

    use Template::TT3::Provider::Cwd;
    
    my $provider = Template::TT3::Provider::Cwd->new;

It uses the L<Cwd|Badger::Filesystem/Cwd> object to store the current working
directory at that point in time.  All template requests will be resolved
relative to that directory.

=head2 fetch($uri)

This method fetches a template from the filesystem identified by the C<$uri> 
argument.  This should be a regular file path, e.g. C<bar.tt3>, C</foo/bar.tt3>,
etc.  Both relative and absolute paths are resolved with respect to the 
current working directory.  Unlike the L<file provider|Template::TT3::Provider::File>,
this does allow you to "navigate" outside of the current working directory.

    my $template = $provider->fetch('example.tt3')
        || die $provider->reason;
        
    my $template = $provider->fetch('subdir/example.tt3')
        || die $provider->reason;
        
    my $template = $provider->fetch('../../updir/example.tt3')
        || die $provider->reason;

It returns a hash array containing a C<file> item which references a
L<Badger::Filesystem::File> object and a C<uri> indicating the definitive path
(i.e. the absolute path, including the root directory of the virtual
filesystem) of the template.  e.g.

    {
        file => $VFS->file('/local/path.tt3'),
        uri  => '/path/to/your/templates/two/local/path.tt3',
    }

If the file cannot be found then the method returns C<undef>, as per
L<Template::TT3::Provider::File>. If an error occurs then an
L<exception|Badger::Exception> will thrown.

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
L<Template::TT3::Provider::File>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


