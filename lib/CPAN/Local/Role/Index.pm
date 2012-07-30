package CPAN::Local::Role::Index;
{
  $CPAN::Local::Role::Index::VERSION = '0.001';
}

# ABSTRACT: Index a repo

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'index';

1;

__END__
=pod

=head1 NAME

CPAN::Local::Role::Index - Index a repo

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

