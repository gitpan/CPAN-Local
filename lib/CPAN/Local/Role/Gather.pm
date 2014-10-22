package CPAN::Local::Role::Gather;
{
  $CPAN::Local::Role::Gather::VERSION = '0.005';
}

# ABSTRACT: Select distributions to add

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'gather';

1;


__END__
=pod

=head1 NAME

CPAN::Local::Role::Gather - Select distributions to add

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Plugins implementing this role are executed at the start of a repository
update. They determine the list of distributions to add.

=head1 INTERFACE

Plugins implementing this role should provide a C<gather> method with the
following interface:

=head2 Parameters

None.

=head2 Returns

List of L<CPAN::Local::Distribution> objects representing distributions that
need to be added to the repository.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

