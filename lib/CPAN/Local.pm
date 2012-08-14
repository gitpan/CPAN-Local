package CPAN::Local;
{
  $CPAN::Local::VERSION = '0.002';
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

version 0.002

=head1 DESCRIPTION

CPAN::Local is a framework for creating custom CPAN implementations. The
individual tasks related to mirror management are handled by separate plugins,
and those plugins can be combined to achieve the desired behavior, or new
ones can be written where further customizations is needed.

This document describes the C<CPAN::Local> class, which represents a local
repository with plugins configured to perform actions on it.

=head1 ATTRIBUTES

=head2 config_filename

Base name of the configuration file. Default is C<cpanlocal>.

=head2 config

A L<Config::MVP::Sequence> representing the mirror configuration. Normally
generated by reading the configuration file (see L</config_filename>).

=head2 root_namespace

The root namespaces for plugins and roles that will be loaded. Default is
C<CPAN::Local>.

=head2 distribution_base_class

The base class for distribution objects. Default is
C<CPAN::Local::Distribution>.

=head2 root

The root directory of the repository. Assumes the current working
directory by default.

=head2 logger

Logging facility. An instance of L<Log::Dispatchouli> by default.

=head2 plugins

All plugins requested by the L</config>, required and instantiated.

=head1 METHODS

=head2 C<plugins_with($role_name)>

Returns all plugins that implement a given role. Only the last portion
of the role name should be passed as an argument - i.e. if C<$role_name>
is C<Index>, then all plugins implementing C<CPAN::Local::Role::Indexa>
will be returned.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

