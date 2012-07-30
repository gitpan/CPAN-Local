package CPAN::Local::Distribution;
{
  $CPAN::Local::Distribution::VERSION = '0.001';
}

# ABSTRACT: Base distribution class

use strict;
use warnings;

use Path::Class ();
use CPAN::DistnameInfo;
use URI;
use Moose;
use namespace::clean -except => 'meta';

has filename => ( is => 'ro', isa => 'Str', required => 1 );
has authorid => ( is => 'ro', isa => 'Str', required => 1 );
has path     => ( is => 'ro', isa => 'Str', required => 1, lazy_build => 1 );

around BUILDARGS => sub
{
    my ( $orig, $class, %args ) = @_;

    # proceed as nomal if we already have authorid
    return $class->$orig(%args) if $args{authorid};
    my $path = Path::Class::file($args{filename});

    # calculate the path, e.g. ('authors', 'id', 'A', 'AD', 'ADAMK', 'File-Which-1.09.tar.gz')
    my @path_parts = ( $path->dir->dir_list, $path->basename );

    # get the last 6 parts of the path
    @path_parts = splice( @path_parts, -6 ) if @path_parts >= 6;

    # make sure we use only forward slashes
    my $distname = Path::Class::file(@path_parts)->as_foreign('Unix')->stringify;

    # get the authorid
    my $distnameinfo = CPAN::DistnameInfo->new($distname);
    $args{authorid} = $distnameinfo->cpanid;

    return $class->$orig(%args);
};

sub _build_path
{
    my $self = shift;

    my $filename = Path::Class::file($self->filename)->basename;

    my @chars = split //, $self->authorid;
    my $path = Path::Class::dir(
        'authors',
        'id',
        $chars[0],
        $chars[0] . $chars[1],
        $self->authorid,
        $filename,
    );

    return $path->as_foreign('Unix')->stringify;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::Distribution - Base distribution class

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

