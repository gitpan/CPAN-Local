package CPAN::Local::Plugin::Duplicates;
{
  $CPAN::Local::Plugin::Duplicates::VERSION = '0.001';
}

# ABSTRACT: Remove duplicates

use strict;
use warnings;

use Moose;
extends 'CPAN::Local::Plugin';
with 'CPAN::Local::Role::Clean';
use namespace::clean -except => 'meta';

sub clean
{
    my ( $self, @distros ) = @_;

    my (%paths, @cleaned);

    foreach my $distro ( @distros )
    {
        next if $paths{$distro->path}++;
        push @cleaned, $distro;
    }

    return @cleaned;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::Plugin::Duplicates - Remove duplicates

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

