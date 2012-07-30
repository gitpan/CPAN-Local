package CPAN::Local::Plugin::Indices;
{
  $CPAN::Local::Plugin::Indices::VERSION = '0.001';
}

# ABSTRACT: Update index files

use strict;
use warnings;

use CPAN::Index::API;
use CPAN::Index::API::Object::Package;
use CPAN::Index::API::File::PackagesDetails;
use File::Path;
use CPAN::DistnameInfo;
use Path::Class qw(file dir);
use URI::file;
use Moose;
extends 'CPAN::Local::Plugin';
with 'CPAN::Local::Role::Initialise';
with 'CPAN::Local::Role::Index';
use namespace::clean -except => 'meta';

has 'repo_uri' =>
(
    is  => 'ro',
    isa => 'Str',
);

has 'root' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'auto_provides' =>
(
    is  => 'ro',
    isa => 'Bool',
);

sub initialise
{
    my $self = shift;

    File::Path::make_path( dir($self->root)->stringify );

    my %args = (
        repo_path => $self->root,
        files => [qw(PackagesDetails MailRc ModList)],
    );
    $args{repo_uri} = $self->repo_uri if $self->repo_uri;

    my $index = CPAN::Index::API->new(%args);

    $index->write_all_files;
}

sub index
{
    my ($self, @distros) = @_;

    my $packages_details =
        CPAN::Index::API::File::PackagesDetails->read_from_repo_path($self->root);

    foreach my $distro ( @distros )
    {
        my %provides = %{ $distro->metadata->provides };

        if ( ! %provides and $self->auto_provides )
        {
            my $distnameinfo = CPAN::DistnameInfo->new(
                file($distro->filename)->basename
            );

            ( my $fake_package = $distnameinfo->dist ) =~ s/-/::/g;

            $provides{$fake_package} = { version => $distnameinfo->version };
        }

        while( my ($package, $specs) = each %provides )
        {
            my $version = $specs->{version};

            if ( my $existing_package = $packages_details->package($package) )
            {
                $existing_package->version($version)
                    if $version > $existing_package->version;
            }
            else
            {
                my $new_package = CPAN::Index::API::Object::Package->new(
                    name         => $package,
                    version      => $version,
                    distribution => $distro->path,
                );
                $packages_details->add_package($new_package);
            }
        }
    }

    $packages_details->write_to_tarball;
}

sub requires_distribution_roles { qw(Metadata) }

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::Plugin::Indices - Update index files

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

