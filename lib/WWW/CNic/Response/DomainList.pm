# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: DomainList.pm,v 1.9 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::DomainList;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::Renewals - a WWW::CNic response object for domain lists.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for domain list requests via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	$response->domains();

Returns an array containing all the domains that match the query.

	$response->regdate($domain);

Returns a Unix timestamp corresponding to the registration date of the domain.

	$response->expirydate($domain);

Returns a Unix timestamp corresponding to the expiry date of the domain.

	$response->status($domain);

Returns a string containing the current status of the domain, for example: 'Live', 'Pending Deletion'.

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

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

sub domains { return grep { /\..{3}$/i } $_[0]->keys() }

sub regdate {
	my ($self, $domain) = @_;
	my @stuff = @{$self->response($domain)};
	return $stuff[1];
}

sub expirydate {
	my ($self, $domain) = @_;
	my @stuff = @{$self->response($domain)};
	return $stuff[2];
}

sub status {
	my ($self, $domain) = @_;
	my @stuff = @{$self->response($domain)};
	return $stuff[0];
}

1;