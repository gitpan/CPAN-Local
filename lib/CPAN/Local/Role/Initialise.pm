package CPAN::Local::Role::Initialise;
{
  $CPAN::Local::Role::Initialise::VERSION = '0.001';
}

# ABSTRACT: Initialize an empty repo

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'initialise';

1;

__END__
=pod

=head1 NAME

CPAN::Local::Role::Initialise - Initialize an empty repo

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

