# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Suffixes.pm,v 1.12 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response::Suffixes;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::Suffixes - a WWW::CNic response object for suffix list lookup.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for suffix list lookup via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	$response->suffixes();

Returns an array containing a list of all the domain suffixes currently supported by CentralNic.

=head1 COPYRIGHT

This module is (c) 2011 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

L<WWW::CNic::Response>

=item *

L<WWW::CNic>

=back

=cut

use WWW::CNic::Response;
@ISA = qw(WWW::CNic::Response);

sub suffixes { return grep { /[A-Z]{2}\.[A-Z]{3}$/i } sort(keys(%{$_[0]->{_response}})) }

1;
