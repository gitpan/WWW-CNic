# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Renewals.pm,v 1.9 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::Renewals;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::Renewals - a WWW::CNic response object for renewal lists.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for retrieving upcoming renewal lists via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

Check L<WWW::CNic::Response> for information about methods available from the base class.

	$response->domains();

This returns an array of domain names that are due for renewal in the given period.

	$response->amount($domain);

This returns the price of the domain renewal (in Sterling) of the C<$domain>.

	$response->expiry($domain);

This returns a UNIX timestamp of the expiry date for C<$domain>.

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

sub amount {
	my ($self, $domain) = @_;
	my @stuff = @{$self->response($domain)};
	return $stuff[0];
}

sub expiry {
	my ($self, $domain) = @_;
	my @stuff = @{$self->response($domain)};
	return $stuff[1];

}

1;