package CPAN::Local;
{
  $CPAN::Local::VERSION = '0.001';
}

# ABSTRACT: Hack custom CPAN repos

use strict;
use warnings;

use Path::Class qw(file dir);
use File::Path  qw(make_path);
use List::MoreUtils qw(uniq apply);
use Class::Load qw(load_class);
use File::Copy;
use CPAN::Local::MVP::Assembler;
use Config::MVP::Reader::Finder;
use Log::Dispatchouli;
use Moose::Meta::Class;

use Moose;
use namespace::clean -except => 'meta';

has 'config' => (
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

has 'root' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '.',
);

has 'root_namespace' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'CPAN::Local',
);

has 'plugins' => (
    is         => 'ro',
    isa        => 'HashRef',
    required   => 1,
    lazy_build => 1,
);

has 'config_filename' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'cpanlocal'
);

has 'logger' =>
(
    is         => 'ro',
    isa        => 'Log::Dispatchouli',
    lazy_build => 1,
);

has 'distribution_base_class' =>
(
    is      => 'ro',
    isa     => 'Str',
    default => 'CPAN::Local::Distribution',
);

sub plugins_with
{
    my ($self, $role) = @_;

    my $role_class = $self->root_namespace . '::Role::';
    $role =~ s/^-/$role_class/;

    my @plugins = grep { $_->does($role) } values %{ $self->plugins };
    return @plugins;
}

sub _build_logger
{
    return Log::Dispatchouli->new({
        ident       => 'CPAN::Local',
        to_stdout   => 1,
        log_pid     => 0,
        quiet_fatal => 'stdout',
    });
}

sub _build_config
{
    my $self = shift;

    my $location = file( $self->root, $self->config_filename )->stringify;

    my $assembler = CPAN::Local::MVP::Assembler->new(
        root_namespace => $self->root_namespace,
    );

    return Config::MVP::Reader::Finder->read_config(
        $location, { assembler => $assembler }
    );
}

sub _build_plugins
{
    my $self = shift;

    my ( %sections, %plugins, @disribution_roles );

    my $distribution_class = $self->distribution_base_class;

    my $role_prefix = "CPAN::Local::Distribution::Role::";

    my @distribution_roles =
        map      { "$role_prefix$_" }
        uniq map { $_->package->requires_distribution_roles }
        apply    { load_class $_->package }
            $self->config->sections;

    if ( @distribution_roles )
    {
        $distribution_class = Moose::Meta::Class->create_anon_class(
            superclasses => [$self->distribution_base_class],
            cache => 1,
            @distribution_roles ? ( roles => \@distribution_roles ) : (),
        )->name;
    }

    for my $section ($self->config->sections)
    {
        my $plugin = $section->package->new(
            %{ $section->payload },
            root   => $self->root,
            logger => $self->logger->proxy({
                proxy_prefix => "[" . $section->name . "] "
            }),
            distribution_class => $distribution_class,
        );
        $plugins{$section->name} = $plugin;
    }

    return \%plugins;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local - Hack custom CPAN repos

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

